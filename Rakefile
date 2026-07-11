# frozen_string_literal: true

require "json"
require "digest"
require "fileutils"
require "open3"
require "rubygems/package"
require "zlib"

module SevgiRelease
  COMPONENT_ORDER = %w[
    sevgi-function
    sevgi-geometry
    sevgi-graphics
    sevgi-standard
    sevgi-derender
    sevgi-sundries
    sevgi
    sevgi-showcase
  ]
    .freeze

  module Preflight
    module_function

    VERSION_PATTERN = /\A\d+\.\d+\.\d+\z/

    def guard!(root:, ref:)
      version = read_version(root)
      raise_error("unsupported release ref: #{ref}") unless allowed_ref?(ref, version)

      validate_versions!(root, version)
      version
    end

    def allowed_ref?(ref, version)
      version.match?(VERSION_PATTERN) &&
        ["refs/heads/main", "refs/tags/v#{version}"].include?(ref)
    end

    def read_version(root)
      version = File.read(File.join(root, "VERSION")).strip
      raise_error("invalid VERSION: #{version.inspect}") unless version.match?(VERSION_PATTERN)

      version
    rescue Errno::ENOENT => e
      raise_error("missing VERSION: #{e.message}")
    end

    def validate_versions!(root, version)
      values = version_values(root)
      missing = values.select { |_file, value| value.nil? }.keys
      mismatches = values.reject { |_file, value| value == version }

      raise_error("missing version constants: #{missing.join(", ")}") unless missing.empty?
      unless mismatches.empty?
        details = mismatches.map { |file, value| "#{file}=#{value}" }.join(", ")
        raise_error("VERSION mismatch: #{details}")
      end

      values
    end

    def version_values(root)
      files = Dir[File.join(root, "*/lib/sevgi/**/version.rb")]
      raise_error("missing version constants") if files.empty?

      files.to_h do |file|
        [file, File.read(file)[/VERSION\s*=\s*"([^"]+)"/, 1]]
      end
    end

    def validate_archives!(root:, package_dir:, version:)
      Archive.validate!(root:, package_dir:, version:)
    end

    def assert_remote!(names:, version:, runner: method(:remote_query))
      names.each do |name|
        output, error, status = runner.call(name)
        raise_error("cannot query RubyGems for #{name}: #{error}") unless status.success?

        if output.match?(/\A#{Regexp.escape(name)} \((?=.*\b#{Regexp.escape(version)}\b)/)
          raise_error("#{name} #{version} is already published")
        end
      end
    end

    def preflight!(root:, ref:, package_dir:, remote_runner: method(:remote_query))
      version = guard!(root:, ref:)
      archives = validate_archives!(root:, package_dir:, version:)
      assert_remote!(names: archives.map { |archive| archive.fetch(:name) }, version:, runner: remote_runner)
      {version:, archives:}
    end

    def gemspecs(root)
      specs = Dir[File.join(root, "*/*.gemspec")].map do |file|
        Gem::Specification.load(file) || raise_error("malformed gemspec: #{file}")
      end

      specs.sort_by { |spec| [COMPONENT_ORDER.index(spec.name) || COMPONENT_ORDER.length, spec.name] }
    end

    def remote_query(name)
      Open3.capture3("gem", "list", "--remote", "--exact", "--all", name)
    end

    def raise_error(message)
      raise Error, message
    end

    module Archive
      module_function

      # Reads and validates the physical members of a gem payload.
      module Payload
        LIMIT = 10 * 1024 * 1024
        private_constant :LIMIT

        module_function

        def read(path)
          entries = nil
          File.open(path, "rb") do |io|
            Gem::Package::TarReader.new(io) { |tar| entries = scan(tar, path) }
          end

          entries || Preflight.raise_error("missing data.tar.gz in #{path}")
        rescue Preflight::Error
          raise
        rescue StandardError => e
          Preflight.raise_error("malformed package container in #{path}: #{e.message}")
        end

        def scan(tar, path)
          entries = nil
          tar.each { |entry| entries = extract(entry, path) || entries }
          entries
        end

        def extract(entry, path)
          case entry.full_name
          when "metadata"
            validate_metadata!(member_read(entry, path), entry.full_name, path)
          when "metadata.gz"
            validate_metadata!(gzip_read(entry, path), entry.full_name, path)
          when "checksums.yaml.gz"
            validate_checksums!(gzip_read(entry, path), entry.full_name, path)
          when "data.tar.gz"
            data_entries(entry, path)
          end
        end

        def data_entries(entry, path)
          with_member(entry.full_name, path) do
            Zlib::GzipReader.wrap(entry) do |gzip|
              Gem::Package::TarReader.new(gzip).map do |item|
                {path: item.full_name, file: item.file?}
              end
            end
          end
        end

        def gzip_read(entry, path)
          with_member(entry.full_name, path) do
            Zlib::GzipReader.wrap(entry) { |gzip| limited_read(gzip) }
          end
        end

        def limited_read(io)
          content = io.read(LIMIT + 1)
          Preflight.raise_error("package member exceeds #{LIMIT} bytes") if content.bytesize > LIMIT

          content
        end

        def member_read(entry, path)
          with_member(entry.full_name, path) { limited_read(entry) }
        end

        def validate_checksums!(content, name, path)
          with_member(name, path) do
            Gem.load_yaml
            checksums = Gem::SafeYAML.safe_load(content)
            Preflight.raise_error("checksum metadata is not a Hash") unless checksums.is_a?(Hash)
          end
        end

        def validate_metadata!(content, name, path)
          with_member(name, path) do
            Gem::Specification.from_yaml(content)
            nil
          end
        end

        def with_member(name, path)
          yield
        rescue StandardError => e
          Preflight.raise_error("malformed #{name} in #{path}: #{e.message}")
        end
      end

      private_constant :Payload

      def validate!(root:, package_dir:, version:)
        specs = Preflight.gemspecs(root)
        Preflight.raise_error("no gemspecs found") if specs.empty?

        specs.map { |spec| validate_one(spec, package_dir:, version:) }
      end

      def validate_one(spec, package_dir:, version:)
        path = File.join(package_dir, "#{spec.name}-#{version}.gem")
        Preflight.raise_error("missing package: #{path}") unless File.file?(path)

        archive, entries = load_archive(path, spec, version)
        validate_contents!(spec, archive, entries, path)

        {name: spec.name, path:, sha256: Digest::SHA256.file(path).hexdigest}
      rescue StandardError => e
        raise e if e.is_a?(Preflight::Error)

        Preflight.raise_error("#{path}: #{e.message}")
      end

      def validate_contents!(spec, archive, entries, path)
        manifest = spec.files
        expected = source_files(spec)
        declared = archive.files
        actual = entries.map { it.fetch(:path) }

        validate_entries!(entries, path)
        validate_file_list!(manifest, path, "gemspec")
        validate_file_list!(declared, path, "metadata")
        validate_match!(declared, actual, path)
        validate_metadata!(expected, declared, path)
        validate_required_files!(actual, path)
      end

      def source_files(spec)
        root = File.dirname(spec.loaded_from)
        spec.files.select { |file| File.file?(File.join(root, file)) }
      end

      def load_archive(path, spec, version)
        entries = Payload.read(path)
        archive = Gem::Package.new(path).spec
        Preflight.raise_error("malformed package name: #{path}") unless archive.name == spec.name
        Preflight.raise_error("malformed package version: #{path}") unless archive.version.to_s == version

        [archive, entries]
      end

      def validate_entries!(entries, path)
        Preflight.raise_error("empty package: #{path}") if entries.empty?

        files = entries.map { it.fetch(:path) }
        validate_file_list!(files, path, "payload")
        invalid = entries.reject { it.fetch(:file) }.map { it.fetch(:path) }
        Preflight.raise_error("non-file package entries in #{path}: #{invalid.join(", ")}") unless invalid.empty?
      end

      def validate_file_list!(files, path, source)
        duplicates = files.tally.select { |_file, count| count > 1 }.keys.sort
        unless duplicates.empty?
          Preflight.raise_error("duplicate package #{source} entries in #{path}: #{duplicates.join(", ")}")
        end

        validate_paths!(files, path)
      end

      def validate_match!(declared, actual, path)
        missing = (declared - actual).sort
        unexpected = (actual - declared).sort
        return if missing.empty? && unexpected.empty?

        details = []
        details << "missing from payload: #{missing.join(", ")}" unless missing.empty?
        details << "unexpected payload entries: #{unexpected.join(", ")}" unless unexpected.empty?
        Preflight.raise_error("package contents mismatch in #{path}: #{details.join("; ")}")
      end

      def validate_metadata!(expected, declared, path)
        missing = (expected - declared).sort
        unexpected = (declared - expected).sort
        return if missing.empty? && unexpected.empty?

        details = []
        details << "missing metadata entries: #{missing.join(", ")}" unless missing.empty?
        details << "unexpected metadata entries: #{unexpected.join(", ")}" unless unexpected.empty?
        Preflight.raise_error("package metadata mismatch in #{path}: #{details.join("; ")}")
      end

      def validate_paths!(files, path)
        invalid = files.select { invalid_path?(it) }
        Preflight.raise_error("invalid package contents in #{path}: #{invalid.join(", ")}") unless invalid.empty?
      end

      def invalid_path?(file)
        return true unless file.is_a?(String) && !file.empty? && file.valid_encoding?

        parts = file.split("/", -1)
        invalid_root?(file) || invalid_parts?(parts)
      end

      def invalid_parts?(parts)
        parts.any?(&:empty?) ||
          parts.include?(".") ||
          parts.include?("..") ||
          parts.include?(".agents") ||
          parts.last == "AGENTS.md"
      end

      def invalid_root?(file)
        file.start_with?("/", "\\") ||
          file.match?(%r{\A[A-Za-z]:[\\/]}) ||
          file.include?("\\") ||
          file.match?(/[[:cntrl:]]/)
      end

      def validate_required_files!(files, path)
        %w[CHANGELOG.md LICENSE README.md].each do |required|
          Preflight.raise_error("missing #{required} in #{path}") unless files.include?(required)
        end
      end
    end

    class Error < StandardError
    end
  end

  module Manifest
    NAME = "SHA256SUMS"

    module_function

    def assert!(package_dir:, archives:, path: File.join(package_dir, NAME))
      Preflight.raise_error("missing release manifest: #{path}") unless File.file?(path)

      entries = entries(path)
      expected = archives.map { |archive| File.basename(archive.fetch(:path)) }
      declared = entries.map(&:first)
      Preflight.raise_error("release manifest order mismatch") unless declared == expected

      assert_archive_set!(package_dir, expected)
      archives.zip(entries).each { |archive, (_name, digest)| assert_checksum!(archive, digest) }
      nil
    end

    def entries(path)
      values = File.readlines(path, chomp: true).map do |line|
        match = /\A([0-9a-f]{64})  ([A-Za-z0-9][A-Za-z0-9._-]*\.gem)\z/.match(line)
        Preflight.raise_error("malformed release manifest: #{line.inspect}") unless match

        [match[2], match[1]]
      end

      Preflight.raise_error("empty release manifest: #{path}") if values.empty?

      values
    end

    def write!(package_dir:, archives:, path: File.join(package_dir, NAME))
      names = archives.map { |archive| File.basename(archive.fetch(:path)) }
      assert_archive_set!(package_dir, names)
      lines = archives.map { |archive| "#{archive.fetch(:sha256)}  #{File.basename(archive.fetch(:path))}" }
      File.write(path, "#{lines.join("\n")}\n")
      assert!(package_dir:, archives:, path:)
      path
    end

    def assert_archive_set!(package_dir, expected)
      Preflight.raise_error("duplicate release archives") unless expected.uniq.size == expected.size

      actual = Dir[File.join(package_dir, "*.gem")].map { File.basename(it) }.sort
      return if actual == expected.sort

      Preflight.raise_error(
        "release archive set mismatch: expected #{expected.sort.join(", ")}; got #{actual.join(", ")}"
      )
    end

    def assert_checksum!(archive, expected)
      relative = File.basename(archive.fetch(:path))
      actual = Digest::SHA256.file(archive.fetch(:path)).hexdigest
      Preflight.raise_error("checksum mismatch: #{relative}") unless expected == actual
    end

    private_class_method :assert_archive_set!, :assert_checksum!, :entries
  end
end

module SevgiBuild
  COMPONENT_ORDER = %w[
    function
    geometry
    graphics
    standard
    derender
    sundries
    toplevel
    showcase
  ].freeze

  module Workspace
    module_function

    def clean!(runner: Open3.method(:capture3))
      output, error, status = runner.call("git", "status", "--short")
      raise "Cannot inspect git status: #{error}" unless status.success?
      raise "Worktree is not clean:\n#{output}" unless output.empty?

      nil
    end

    def main!(runner: Open3.method(:capture3))
      branch, error, status = runner.call("git", "branch", "--show-current")
      raise "Cannot inspect git branch: #{error}" unless status.success?
      raise "Release requires the main branch" unless branch.strip == "main"

      nil
    end
  end

  module Docs
    PRIVATE_PAGES = %w[
      Sevgi/Executor/Scope.html
      Sevgi/Executor/Source.html
      Sevgi/Geometry/Equation/Quadratic.html
      Sevgi/Sundries/Export/Renderer.html
    ]
      .freeze

    private_constant :PRIVATE_PAGES
    module_function

    def build!(root:, remover: FileUtils.method(:rm_rf), runner: method(:run))
      remover.call(File.join(root, ".cache/ruby/doc/api"))
      remover.call(File.join(root, ".cache/ruby/yardoc"))
      runner.call("yard", "doc", "--fail-on-warning")
    end

    def complete!(runner: Open3.method(:capture3), reporter: Kernel.method(:warn))
      output, error, status = runner.call("yard", "stats", "--list-undoc")
      raise "YARD stats failed: #{error}" unless status.success?

      undocumented = output.lines.grep(/\(\s*[1-9]\d* undocumented\)/)
      raise "Undocumented public API objects:\n#{output}" unless undocumented.empty?

      reporter.call(output)
      output
    end

    def hide_private!(root:)
      pages = PRIVATE_PAGES.map { File.join(root, ".cache/ruby/doc/api", it) }
      present = pages.select { File.exist?(it) }
      raise "Private API pages are exposed:\n#{present.join("\n")}" unless present.empty?

      nil
    end

    def run(*args)
      system(*args, exception: true)
    end

    private_class_method :run
  end

  module Coverage
    # Preserve the pre-Rakefile baseline while counting the root build code in the denominator.
    FLOORS = {
      branch: 80.04,
      line: 97.05
    }.freeze

    module_function

    def totals(report)
      totals = {
        branch: {covered: 0, total: 0},
        line: {covered: 0, total: 0}
      }

      data(report).each_value do |file|
        accumulate!(totals.fetch(:line), file.fetch("lines"))
        accumulate!(totals.fetch(:branch), file.fetch("branches", []).map { it.fetch("coverage") })
      end

      totals.transform_values { percent(it.fetch(:covered), it.fetch(:total)) }
    end

    def files(report)
      data(report).keys.map { File.expand_path(it) }.sort
    end

    def require_files!(report, expected)
      missing = expected - files(report)
      raise "Coverage report is missing tracked files:\n#{missing.join("\n")}" unless missing.empty?

      nil
    end

    def require_floors!(totals, floors = FLOORS)
      failures = floors.filter_map do |criterion, floor|
        total = totals.fetch(criterion)
        "#{criterion}: #{format("%.2f", total)}% < #{format("%.2f", floor)}%" if total < floor
      end

      raise "Coverage below floor:\n#{failures.join("\n")}" unless failures.empty?

      nil
    end

    def data(report) = JSON.parse(File.read(report)).fetch("coverage")

    def accumulate!(total, values)
      values.grep(Integer).each do |coverage|
        total[:covered] += 1 if coverage.positive?
        total[:total] += 1
      end
    end

    def percent(covered, total) = total.zero? ? 100.0 : ((covered * 100.0) / total)

    private_class_method :accumulate!, :data, :percent
  end
end

Rake::FileUtilsExt.verbose_flag = false

task_label = -> (string) { "\e[1;33m#{string}\e[0m" }

rootdir = File.expand_path(__dir__)
version = File.read(File.join(rootdir, "VERSION")).strip
pkgdir = File.expand_path(ENV.fetch("PKGDIR", "pkg"), rootdir)
projects = Dir[File.join(rootdir, "*/*.gemspec")].to_h do |file|
  project = File.dirname(file).delete_prefix("#{rootdir}/")
  [project, File.basename(file, ".*")]
end

order = SevgiBuild::COMPONENT_ORDER
names = (order & projects.keys) + (projects.keys - order).sort
tracked_sources = [
  File.join(rootdir, "Rakefile"),
  *names.flat_map { |project| Dir[File.join(rootdir, project, "lib/**/*.rb")] }
].map { File.expand_path(it) }.sort

directory(pkgdir)

names.each do |project|
  package = projects.fetch(project)

  namespace(project) do
    gem = "#{pkgdir}/#{package}-#{version}.gem"
    gemspec = "#{package}.gemspec"

    %i[lint test].each do |tn|
      desc("#{tn.capitalize} #{project.capitalize}")
      task(tn) do |t|
        warn(task_label.call(t))
        Dir.chdir(File.join(rootdir, project)) do
          sh("rake", tn.to_s)
        end

        warn("")
      end
    end

    desc("Package #{package}")
    task(package: [pkgdir]) do |t|
      warn(task_label.call(t))
      Dir.chdir(File.join(rootdir, project)) do
        sh("gem", "build", gemspec, "--output", gem)
      end

      warn("")
    end

    desc("Build #{package}")
    task(build: :package)
  end
end

%i[build lint test].each do |tn|
  desc("#{tn.capitalize} all")
  task(tn => names.map { |project| "#{project}:#{tn}" })
end

desc("Lint root build tasks")
task("lint:root") do
  sh("bundle", "exec", "rubocop", "Rakefile", "--display-cop-names")
end

Rake::Task[:lint].enhance(["lint:root"])

namespace(:release) do
  desc("Guard release ref and versions")
  task(:guard) do
    SevgiRelease::Preflight.guard!(root: rootdir, ref: ENV.fetch("GITHUB_REF"))
  end

  desc("Validate built release archives")
  task(:verify) do
    result = SevgiRelease::Preflight.preflight!(root: rootdir, ref: ENV.fetch("GITHUB_REF"), package_dir: pkgdir)
    SevgiRelease::Manifest.write!(package_dir: pkgdir, archives: result.fetch(:archives))
  end

  desc("Check release workspace")
  task(:preflight) do
    SevgiBuild::Workspace.clean!
    SevgiBuild::Workspace.main!

    Rake::Task[:build].invoke
    manifest = SevgiRelease::Preflight.preflight!(
      root: rootdir,
      ref: "refs/heads/main",
      package_dir: pkgdir
    )
    SevgiRelease::Manifest.write!(package_dir: pkgdir, archives: manifest.fetch(:archives))
  end
end

desc("Release all")
task(release: "release:preflight") do
  manifest = SevgiRelease::Preflight.preflight!(root: rootdir, ref: "refs/heads/main", package_dir: pkgdir)
  SevgiRelease::Manifest.assert!(package_dir: pkgdir, archives: manifest.fetch(:archives))
  manifest.fetch(:archives).each { |archive| sh("gem", "push", archive.fetch(:path)) }
  SevgiBuild::Workspace.clean!
end

desc("Build API documentation")
task(:doc) do
  SevgiBuild::Docs.build!(root: rootdir)
end

namespace(:doc) do
  desc("Check API documentation")
  task(:check) do
    SevgiBuild::Docs.build!(root: rootdir)
    SevgiBuild::Docs.complete!
    SevgiBuild::Docs.hide_private!(root: rootdir)
  end
end

desc("Run coverage")
task(coverage: "coverage:check")

namespace(:coverage) do
  desc("Run tests with coverage")
  task(:test) do
    rm_rf(".cache/ruby/coverage")
    sh({"COVERAGE" => "1"}, "bundle", "exec", "rake", "test")
  end

  desc("Check coverage")
  task(check: :test) do
    report = File.join(rootdir, ".cache/ruby/coverage/coverage.json")
    SevgiBuild::Coverage.require_files!(report, tracked_sources)
    totals = SevgiBuild::Coverage.totals(report)
    SevgiBuild::Coverage.require_floors!(totals)
    warn("Line coverage: #{format("%.2f", totals.fetch(:line))}%")
    warn("Branch coverage: #{format("%.2f", totals.fetch(:branch))}%")
  end
end

namespace(:clean) do
  desc("Clean coverage reports")
  task(:coverage) do
    rm_rf(File.join(rootdir, ".cache/ruby/coverage"))
  end
end

desc("Bump versions")
task(:bump) do
  if ENV["version"]
    File.write("#{rootdir}/VERSION", version = ENV["version"])
  end

  Dir[File.join(rootdir, "*/**/version.rb")].each do |source|
    File.write(
      source,
      File.read(source).gsub(/^(\s*)VERSION(\s*)= .*?$/, "\\1VERSION = \"#{version}\"")
    )
  end
end

desc("Clean all")
task(:clean) do
  rm_rf(pkgdir)
end

desc("Make (almost) all")
task(all: %i[lint test])

task(default: :test)
