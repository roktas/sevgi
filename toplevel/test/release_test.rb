# frozen_string_literal: true

require "digest"
require "fileutils"
require "psych"
require "rake"
require "stringio"
require "tmpdir"
require "zlib"

require_relative "test_helper"

load(File.expand_path("../../Rakefile", __dir__)) unless defined?(SevgiRelease::Preflight)

module Sevgi
  class ReleaseTest < Minitest::Test
    Manifest = ::SevgiRelease::Manifest
    Preflight = ::SevgiRelease::Preflight
    PAYLOAD = {
      "CHANGELOG.md" => "changes\n",
      "LICENSE" => "license\n",
      "README.md" => "demo\n",
      "lib/sevgi/version.rb" => "VERSION = \"1.2.3\"\n"
    }.freeze

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
          sevgi-appendix
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

        manifest = Manifest.write!(package_dir:, archives:)

        assert_equal(
          archives.map { "#{it.fetch(:sha256)}  #{File.basename(it.fetch(:path))}" },
          File.readlines(manifest, chomp: true)
        )
        assert_nil(Manifest.assert!(package_dir:, archives:))

        lines = File.readlines(manifest)
        File.write(manifest, lines.reverse.join)
        assert_raises(Preflight::Error) { Manifest.assert!(package_dir:, archives:) }
      end
    end

    def test_manifest_rejects_archive_set_drift
      Dir.mktmpdir do |package_dir|
        path = File.join(package_dir, "demo-1.2.3.gem")
        File.write(path, "demo")
        archive = {name: "demo", path:, sha256: Digest::SHA256.file(path).hexdigest}
        archives = [archive]
        manifest = Manifest.write!(package_dir:, archives:)
        line = File.read(manifest)

        File.write(File.join(package_dir, "extra-1.2.3.gem"), "extra")
        assert_raises(Preflight::Error) { Manifest.assert!(package_dir:, archives:) }
        FileUtils.rm(File.join(package_dir, "extra-1.2.3.gem"))

        File.write(manifest, line + line)
        assert_raises(Preflight::Error) { Manifest.assert!(package_dir:, archives:) }

        File.write(manifest, line.sub(/\A[0-9a-f]{64}/, "0" * 64))
        assert_raises(Preflight::Error) { Manifest.assert!(package_dir:, archives:) }

        FileUtils.rm(manifest)
        assert_raises(Preflight::Error) { Manifest.assert!(package_dir:, archives:) }
      end
    end

    def test_manifest_rejects_malformed_empty_and_duplicates
      Dir.mktmpdir do |package_dir|
        path = File.join(package_dir, "demo-1.2.3.gem")
        File.write(path, "demo")
        archive = {name: "demo", path:, sha256: Digest::SHA256.file(path).hexdigest}
        manifest = File.join(package_dir, "SHA256SUMS")

        ["", "not a manifest\n"].each do |content|
          File.write(manifest, content)
          assert_raises(Preflight::Error) do
            Manifest.assert!(package_dir:, archives: [archive], path: manifest)
          end
        end

        assert_raises(Preflight::Error) do
          Manifest.write!(package_dir:, archives: [archive, archive], path: manifest)
        end
      end
    end

    def test_guard_rejects_unsupported_ref
      with_release_fixture do |root|
        error = assert_raises(Preflight::Error) do
          Preflight.guard!(root:, ref: "refs/heads/review")
        end

        assert_match(/unsupported release ref/, error.message)
      end
    end

    def test_guard_rejects_missing_and_mismatched_versions
      with_release_fixture do |root|
        File.write(File.join(root, "demo/lib/sevgi/version.rb"), "# missing constant\n")
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

    def test_archive_rejects_malformed_container
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        FileUtils.mkdir_p(package_dir)
        File.binwrite(File.join(package_dir, "demo-1.2.3.gem"), "x" * 512)

        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
        end

        assert_match(/malformed package container/, error.message)
      end
    end

    def test_archive_rejects_missing_gemspecs
      Dir.mktmpdir do |root|
        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir: File.join(root, "pkg"), version: "1.2.3")
        end

        assert_match(/no gemspecs found/, error.message)
      end
    end

    def test_archive_rejects_empty_payload
      with_release_fixture do |root|
        write_project_gemspec(root, [])
        write_release_package(root, declared: [], entries: {})

        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir: File.join(root, "pkg"), version: "1.2.3")
        end

        assert_match(/empty package/, error.message)
      end
    end

    def test_archive_rejects_wrong_name_and_version
      cases = [
        [{name: "other"}, /malformed package name/],
        [{version: "9.9.9"}, /malformed package version/]
      ]

      cases.each do |attributes, message|
        with_release_fixture do |root|
          metadata = gzip(release_spec(PAYLOAD.keys, **attributes).to_yaml)
          write_release_package(
            root,
            declared: PAYLOAD.keys,
            entries: PAYLOAD,
            members: {"metadata.gz" => metadata}
          )

          error = assert_raises(Preflight::Error) do
            Preflight.validate_archives!(root:, package_dir: File.join(root, "pkg"), version: "1.2.3")
          end

          assert_match(message, error.message)
        end
      end
    end

    def test_archive_accepts_plain_metadata
      with_release_fixture do |root|
        metadata = release_spec(PAYLOAD.keys).to_yaml
        write_release_package(root, declared: PAYLOAD.keys, entries: PAYLOAD, members: {"metadata" => metadata})

        archives = Preflight.validate_archives!(root:, package_dir: File.join(root, "pkg"), version: "1.2.3")

        assert_equal(["demo"], archives.map { it.fetch(:name) })
      end
    end

    def test_archive_rejects_invalid_metadata
      with_release_fixture do |root|
        write_release_package(root, declared: PAYLOAD.keys, entries: PAYLOAD, members: {"metadata" => "--- text\n"})

        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir: File.join(root, "pkg"), version: "1.2.3")
        end

        assert_match(/YAML data doesn't evaluate to gem specification/, error.message)
      end
    end

    def test_archive_rejects_oversized_metadata
      with_release_fixture do |root|
        content = gzip("x" * ((10 * 1024 * 1024) + 1))
        write_release_package(root, declared: PAYLOAD.keys, entries: PAYLOAD, members: {"metadata.gz" => content})

        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir: File.join(root, "pkg"), version: "1.2.3")
        end

        assert_match(/package member exceeds/, error.message)
      end
    end

    def test_archive_compares_declared_and_actual_files
      cases = [
        [PAYLOAD.keys + ["lib/claimed.rb"], PAYLOAD, %r{missing.*lib/claimed\.rb}],
        [PAYLOAD.keys, PAYLOAD.merge("lib/extra.rb" => "extra\n"), %r{unexpected.*lib/extra\.rb}]
      ]

      cases.each do |declared, entries, message|
        with_release_fixture do |root|
          package_dir = File.join(root, "pkg")
          write_project_gemspec(root, declared)
          write_release_package(root, declared:, entries:)

          error = assert_raises(Preflight::Error) do
            Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
          end

          assert_match(message, error.message)
        end
      end
    end

    def test_archive_matches_project_gemspec
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        cases = [
          PAYLOAD.merge("lib/extra.rb" => "extra\n"),
          PAYLOAD.except("lib/sevgi/version.rb")
        ]

        cases.each do |entries|
          write_release_package(root, declared: entries.keys, entries:)

          error = assert_raises(Preflight::Error) do
            Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
          end

          assert_match(/package metadata mismatch/, error.message)
        end
      end
    end

    def test_archive_ignores_source_directories_like_gem_build
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        write_project_gemspec(root, PAYLOAD.keys + ["lib", "lib/sevgi"])
        write_release_package(root, declared: PAYLOAD.keys, entries: PAYLOAD)

        archives = Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")

        assert_equal(["demo"], archives.map { it.fetch(:name) })
      end
    end

    def test_archive_rejects_duplicate_payload_entries
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        entries = PAYLOAD.to_a + [["README.md", "duplicate\n"]]
        write_release_package(root, declared: PAYLOAD.keys, entries:)

        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
        end

        assert_match(/duplicate.*README\.md/, error.message)
      end
    end

    def test_archive_rejects_non_file_payload_entries
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        declared = PAYLOAD.keys + ["lib"]
        write_project_gemspec(root, declared)
        write_release_package(root, declared:, entries: PAYLOAD, directories: ["lib"])

        error = assert_raises(Preflight::Error) do
          Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
        end

        assert_match(/non-file package entries.*lib/, error.message)
      end
    end

    def test_archive_rejects_unsafe_payload_paths
      invalid = [
        "/absolute",
        "C:/absolute",
        "../escape",
        "lib/../../escape",
        "lib\\..\\escape",
        ".agents/secret",
        "nested/.agents/secret",
        "AGENTS.md",
        "nested/AGENTS.md"
      ]

      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")

        invalid.each do |path|
          entries = PAYLOAD.merge(path => "forbidden\n")
          write_release_package(root, declared: entries.keys, entries:)

          error = assert_raises(Preflight::Error) do
            Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
          end

          assert_includes(error.message, path)
        end
      end
    end

    def test_archive_requires_canonical_payload_files
      %w[CHANGELOG.md LICENSE README.md].each do |required|
        with_release_fixture do |root|
          package_dir = File.join(root, "pkg")
          entries = PAYLOAD.reject { |path, _content| path == required }
          write_project_gemspec(root, entries.keys)
          write_release_package(root, declared: entries.keys, entries:)

          error = assert_raises(Preflight::Error) do
            Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
          end

          assert_match(/missing #{Regexp.escape(required)}/, error.message)
        end
      end
    end

    def test_archive_reports_malformed_members_before_remote
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        cases = [
          ["metadata.gz", "broken"],
          ["metadata.gz", gzip("broken")],
          ["data.tar.gz", "broken"],
          ["data.tar.gz", gzip("x" * 512)],
          ["checksums.yaml.gz", "broken"],
          ["checksums.yaml.gz", gzip("broken")]
        ]

        cases.each do |member, content|
          write_release_package(root, declared: PAYLOAD.keys, entries: PAYLOAD, members: {member => content})
          calls = 0

          error = assert_raises(Preflight::Error) do
            Preflight.preflight!(
              root:,
              ref: "refs/heads/main",
              package_dir:,
              remote_runner: -> (_name) {
                calls += 1
                ["", "", status(true)]
              }
            )
          end

          assert_match(/malformed #{Regexp.escape(member)}/, error.message)
          assert_equal(0, calls)
        end
      end
    end

    def test_archive_rejects_checksum_mismatch_before_remote
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        checksums = gzip(Psych.dump("SHA256" => {"metadata.gz" => "0" * 64, "data.tar.gz" => "0" * 64}))
        write_release_package(
          root,
          declared: PAYLOAD.keys,
          entries: PAYLOAD,
          members: {"checksums.yaml.gz" => checksums}
        )
        calls = 0

        error = assert_raises(Preflight::Error) do
          Preflight.preflight!(
            root:,
            ref: "refs/heads/main",
            package_dir:,
            remote_runner: -> (_name) {
              calls += 1
              ["", "", status(true)]
            }
          )
        end

        assert_match(/checksum mismatch/, error.message)
        assert_equal(0, calls)
      end
    end

    def test_archive_validation_is_cwd_independent
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        write_release_package(root, declared: PAYLOAD.keys, entries: PAYLOAD)

        Dir.mktmpdir do |cwd|
          archives = Dir.chdir(cwd) do
            Preflight.validate_archives!(root:, package_dir:, version: "1.2.3")
          end

          assert_equal(["demo"], archives.map { it.fetch(:name) })
        end
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

    def test_preflight_accepts_unpublished_archives
      with_release_fixture do |root|
        package_dir = File.join(root, "pkg")
        write_release_package(root, declared: PAYLOAD.keys, entries: PAYLOAD)
        queried = []

        result = Preflight.preflight!(
          root:,
          ref: "refs/heads/main",
          package_dir:,
          remote_runner: -> (name) {
            queried << name
            ["#{name} (1.2.2)", "", status(true)]
          }
        )

        assert_equal("1.2.3", result.fetch(:version))
        assert_equal(["demo"], queried)
      end
    end

    def test_remote_query_uses_exact_all_versions
      args = nil
      result = ["demo (1.2.3)", "", status(true)]

      Open3.stub(
        :capture3,
        -> (*command) {
          args = command
          result
        }
      ) do
        assert_same(result, Preflight.remote_query("demo"))
      end

      assert_equal(%w[gem list --remote --exact --all demo], args)
    end

    def test_workflow_uses_tracked_guard_and_pinned_actions
      ship = File.read(File.expand_path("../../.github/workflows/ship.yml", __dir__))

      assert_includes(ship, "Rake::Task[\"release:guard\"].invoke")
      assert_includes(ship, "bundle exec rake release:verify")
      ship.scan(/^\s+uses:\s+([^\s]+)$/).flatten.each do |reference|
        assert_match(/@[0-9a-f]{40}\z/, reference)
      end
    end

    private

    def data_tar(entries, directories: [])
      io = StringIO.new("".b)
      Gem::Package::TarWriter.new(io) do |tar|
        directories.each { |path| tar.mkdir(path, 0o755) }
        entries.each do |path, content|
          tar.add_file_simple(path, 0o644, content.bytesize) { it.write(content) }
        end
      end

      io.string
    end

    def gzip(content)
      io = StringIO.new("".b)
      gzip = Zlib::GzipWriter.new(io)
      gzip.write(content)
      gzip.close
      io.string
    end

    def release_spec(files, name: "demo", version: "1.2.3")
      Gem::Specification.new do |spec|
        spec.name = name
        spec.version = version
        spec.summary = "demo"
        spec.authors = ["Test"]
        spec.files = files
      end
    end

    def write_release_package(
      root,
      declared:,
      entries:,
      members: {},
      directories: []
    )
      package_dir = File.join(root, "pkg")
      path = File.join(package_dir, "demo-1.2.3.gem")
      metadata = gzip(release_spec(declared).to_yaml)
      contents = gzip(data_tar(entries, directories:))
      payload = {"metadata.gz" => metadata, "data.tar.gz" => contents, **members}

      FileUtils.mkdir_p(package_dir)
      File.open(path, "wb") do |io|
        Gem::Package::TarWriter.new(io) do |tar|
          payload.each do |name, content|
            tar.add_file_simple(name, 0o444, content.bytesize) { it.write(content) }
          end
        end
      end

      path
    end

    def write_project_gemspec(root, files)
      File.write(
        File.join(root, "demo/demo.gemspec"),
        <<~RUBY
          Gem::Specification.new do |s|
            s.name = "demo"
            s.version = "1.2.3"
            s.summary = "demo"
            s.files = #{files.inspect}
          end
        RUBY
      )
    end

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
        write_project_gemspec(root, PAYLOAD.keys)

        yield root
      end
    end
  end
end
