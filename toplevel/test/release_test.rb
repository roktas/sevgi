# frozen_string_literal: true

require "digest"
require "fileutils"
require "rake"
require "tmpdir"

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

    def test_manifest_preserves_archive_order
      Dir.mktmpdir do |package_dir|
        archives = %w[zeta alpha].map do |name|
          path = File.join(package_dir, "#{name}-1.2.3.gem")
          File.write(path, name)
          {name:, path:, sha256: Digest::SHA256.file(path).hexdigest}
        end

        manifest = Preflight.write_manifest!(package_dir:, archives:)

        assert_equal(
          archives.map { "#{it.fetch(:sha256)}  #{File.basename(it.fetch(:path))}" },
          File.readlines(manifest, chomp: true)
        )
        assert_nil(Preflight.assert_checksums!(package_dir:, archives:))

        lines = File.readlines(manifest)
        File.write(manifest, lines.reverse.join)
        assert_raises(Preflight::Error) { Preflight.assert_checksums!(package_dir:, archives:) }
      end
    end

    def test_manifest_rejects_archive_set_drift
      Dir.mktmpdir do |package_dir|
        path = File.join(package_dir, "demo-1.2.3.gem")
        File.write(path, "demo")
        archive = {name: "demo", path:, sha256: Digest::SHA256.file(path).hexdigest}
        archives = [archive]
        manifest = Preflight.write_manifest!(package_dir:, archives:)
        line = File.read(manifest)

        File.write(File.join(package_dir, "extra-1.2.3.gem"), "extra")
        assert_raises(Preflight::Error) { Preflight.assert_checksums!(package_dir:, archives:) }
        FileUtils.rm(File.join(package_dir, "extra-1.2.3.gem"))

        File.write(manifest, line + line)
        assert_raises(Preflight::Error) { Preflight.assert_checksums!(package_dir:, archives:) }

        File.write(manifest, line.sub(/\A[0-9a-f]{64}/, "0" * 64))
        assert_raises(Preflight::Error) { Preflight.assert_checksums!(package_dir:, archives:) }

        FileUtils.rm(manifest)
        assert_raises(Preflight::Error) { Preflight.assert_checksums!(package_dir:, archives:) }
      end
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

    def test_remote_failure_is_reported
      error = assert_raises(Preflight::Error) do
        Preflight.assert_remote!(
          names: ["demo"],
          version: "1.2.3",
          runner: -> (_name) { ["", "network", status(false)] }
        )
      end

      assert_match(/cannot query RubyGems/, error.message)
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
  end
end
