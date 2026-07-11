# frozen_string_literal: true

require "fileutils"
require "open3"
require "rake"
require "rubygems/package"

require_relative "test_helper"

load(File.expand_path("../../Rakefile", __dir__)) unless defined?(SevgiRelease::Preflight)

module Sevgi
  class ReleaseTest < Minitest::Test
    Preflight = ::SevgiRelease::Preflight

    def test_allowed_ref_accepts_main_and_exact_tag
      assert(Preflight.allowed_ref?("refs/heads/main", "1.2.3"))
      assert(Preflight.allowed_ref?("refs/tags/v1.2.3", "1.2.3"))
      refute(Preflight.allowed_ref?("refs/heads/review", "1.2.3"))
      refute(Preflight.allowed_ref?("refs/tags/v0.0.0", "1.2.3"))
      refute(Preflight.allowed_ref?("refs/tags/v1.2", "1.2"))
    end

    def test_archive_order_matches_component_dependencies
      root = File.expand_path("../..", __dir__)

      assert_equal(
        %w[
          sevgi-function
          sevgi-geometry
          sevgi-graphics
          sevgi-standard
          sevgi-derender
          sevgi-sundries
          sevgi
          sevgi-showcase
        ],
        Preflight.gemspecs(root).map(&:name)
      )
    end

    def test_guard_rejects_missing_and_mismatched_versions
      with_release_fixture do |root|
        FileUtils.rm(File.join(root, "demo/lib/sevgi/version.rb"))
        error = assert_raises(Preflight::Error) { Preflight.guard!(root:, ref: "refs/heads/main") }
        assert_match(/missing version constants/, error.message)

        File.write(File.join(root, "demo/lib/sevgi/version.rb"), "VERSION = \"9.9.9\"\\n")
        error = assert_raises(Preflight::Error) { Preflight.guard!(root:, ref: "refs/heads/main") }
        assert_match(/VERSION mismatch/, error.message)
      end
    end

    def test_read_version_rejects_missing_and_invalid_files
      Dir.mktmpdir do |root|
        error = assert_raises(Preflight::Error) { Preflight.read_version(root) }
        assert_match(/missing VERSION/, error.message)

        File.write(File.join(root, "VERSION"), "1.2\n")
        error = assert_raises(Preflight::Error) { Preflight.read_version(root) }
        assert_match(/invalid VERSION/, error.message)
      end
    end

    def test_version_validation_rejects_empty_project
      Dir.mktmpdir do |root|
        File.write(File.join(root, "VERSION"), "1.2.3\n")
        error = assert_raises(Preflight::Error) { Preflight.validate_versions!(root, "1.2.3") }
        assert_match(/missing version constants/, error.message)
      end
    end

    def test_archive_preflight_rejects_missing_package
      with_release_fixture do |root|
        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir: File.join(root, "pkg"), version: "1.2.3")
        end

        assert_match(/missing package/, error.message)
      end
    end

    def test_archive_preflight_rejects_malformed_archive
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        FileUtils.mkdir_p(package_dir)
        File.binwrite(File.join(package_dir, "demo-1.2.3.gem"), "not a gem")

        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
        end

        assert_match(/demo-1\.2\.3\.gem/, error.message)
      end
    end

    def test_remote_preflight_rejects_existing_version
      runner = -> (_name) { ["demo (1.2.3)", "", status(true)] }

      error = assert_raises(Preflight::Error) do
        Preflight.assert_remote!(names: ["demo"], version: "1.2.3", runner:)
      end

      assert_match(/already published/, error.message)
    end

    def test_publish_does_not_push_after_archive_failure
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        FileUtils.mkdir_p(package_dir)
        File.binwrite(File.join(package_dir, "demo-1.2.3.gem"), "not a gem")
        pushes = []

        assert_raises(Preflight::Error) do
          Preflight.publish!(root:, ref: "refs/heads/main", package_dir:, push: -> (path) { pushes << path })
        end

        assert_empty(pushes)
      end
    end

    def test_publish_does_not_push_after_remote_or_checksum_failure
      with_release_fixture do |root|
        package_dir = build_fixture_package(root)
        pushes = []
        remote_ok = -> (_name) { ["demo ()", "", status(true)] }
        remote_conflict = -> (_name) { ["demo (1.2.3)", "", status(true)] }

        assert_raises(Preflight::Error) do
          Preflight.publish!(
            root:,
            ref: "refs/heads/main",
            package_dir:,
            remote_runner: remote_conflict,
            push: -> (path) { pushes << path }
          )
        end

        assert_empty(pushes)

        File.write(File.join(package_dir, "SHA256SUMS"), "#{"0" * 64}  demo-1.2.3.gem\n")
        assert_raises(Preflight::Error) do
          Preflight.publish!(
            root:,
            ref: "refs/heads/main",
            package_dir:,
            remote_runner: remote_ok,
            push: -> (path) { pushes << path }
          )
        end

        assert_empty(pushes)
      end
    end

    def test_publish_accepts_valid_checksum_and_pushes_in_order
      with_release_fixture do |root|
        package_dir = build_fixture_package(root)
        archives = Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
        assert_nil(Preflight.assert_checksums!(package_dir:, archives:))

        digest = Digest::SHA256.file(archives.first.fetch(:path)).hexdigest
        File.write(File.join(package_dir, "SHA256SUMS"), "#{digest}  demo-1.2.3.gem\n")
        pushes = []
        remote_ok = -> (_name) { ["demo ()", "", status(true)] }

        result = Preflight.publish!(
          root:,
          ref: "refs/heads/main",
          package_dir:,
          remote_runner: remote_ok,
          push: -> (path) { pushes << path }
        )

        assert_equal(archives, result.fetch(:archives))
        assert_equal([archives.first.fetch(:path)], pushes)
      end
    end

    def test_remote_and_push_failures_are_reported
      error = assert_raises(Preflight::Error) do
        Preflight.assert_remote!(
          names: ["demo"],
          version: "1.2.3",
          runner: -> (_name) { ["", "network", status(false)] }
        )
      end

      assert_match(/cannot query RubyGems/, error.message)

      [
        ["failure", "denied", status(false)],
        ["failure", "", status(false)]
      ].each do |output, error_text, result|
        error = assert_raises(Preflight::Error) do
          Open3.stub(:capture3, [output, error_text, result]) { Preflight.push_gem("demo.gem") }
        end

        assert_match(/gem push failed/, error.message)
      end

      Open3.stub(:capture3, ["", "", status(true)]) { assert_nil(Preflight.push_gem("demo.gem")) }
    end

    def test_workflow_uses_tracked_guard_and_pinned_actions
      ship = File.read(File.expand_path("../../.github/workflows/ship.yml", __dir__))

      assert_includes(ship, "Rake::Task[\"release:guard\"].invoke")
      assert_includes(ship, "bundle exec rake release:verify")
      refute_includes(ship, "script/release.rb")
      ship.scan(/^\s+uses:\s+([^\s]+)$/).flatten.each do |reference|
        assert_match(/@[0-9a-f]{40}\z/, reference)
      end
    end

    private

    def status(success)
      Struct.new(:success?).new(success)
    end

    def with_release_fixture
      Dir.mktmpdir do |root|
        FileUtils.mkdir_p(File.join(root, "demo/lib/sevgi"))
        File.write(File.join(root, "VERSION"), "1.2.3\n")
        File.write(File.join(root, "demo/lib/sevgi/version.rb"), "VERSION = \"1.2.3\"\n")
        File.write(File.join(root, "demo/README.md"), "demo\n")
        File.write(File.join(root, "demo/LICENSE"), "license\n")
        File.write(File.join(root, "demo/CHANGELOG.md"), "changes\n")
        File.write(
          File.join(root, "demo/demo.gemspec"),
          <<~RUBY
            Gem::Specification.new do |s|
              s.name = "demo"
              s.version = "1.2.3"
              s.summary = "demo"
              s.files = %w[CHANGELOG.md LICENSE README.md lib/sevgi/version.rb]
            end
          RUBY
        )

        yield root
      end
    end

    def build_fixture_package(root)
      component = File.join(root, "demo")
      package_dir = File.join(root, "pkg")
      FileUtils.mkdir_p(package_dir)
      package = File.join(package_dir, "demo-1.2.3.gem")

      capture_io do
        Dir.chdir(component) do
          Gem::Package.build(Gem::Specification.load("demo.gemspec"), true, false, package)
        end
      end

      package_dir
    end
  end
end
