# frozen_string_literal: true

require "json"
require "digest"
require "open3"
require "rubygems/package"

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

    def assert_checksums!(package_dir:, archives:, path: File.join(package_dir, "SHA256SUMS"))
      return unless File.file?(path)

      expected = checksum_entries(path)
      archives.each { |archive| assert_checksum!(archive, expected) }
    end

    def checksum_entries(path)
      File.readlines(path, chomp: true).to_h do |line|
        digest, relative = line.split("  ", 2)
        [relative, digest]
      end
    end

    def assert_checksum!(archive, expected)
      relative = File.basename(archive.fetch(:path))
      actual = Digest::SHA256.file(archive.fetch(:path)).hexdigest
      raise_error("checksum mismatch: #{relative}") unless expected.fetch(relative, nil) == actual
    end

    def publish!(root:, ref:, package_dir:, remote_runner: method(:remote_query), push: method(:push_gem))
      result = preflight!(root:, ref:, package_dir:, remote_runner:)
      assert_checksums!(package_dir:, archives: result.fetch(:archives))
      result.fetch(:archives).each { |archive| push.call(archive.fetch(:path)) }
      result
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

    def push_gem(path)
      output, error, status = Open3.capture3("gem", "push", path)
      raise_error("gem push failed for #{path}: #{error.empty? ? output : error}") unless status.success?
    end

    def raise_error(message)
      raise Error, message
    end

    module Archive
      module_function

      def validate!(root:, package_dir:, version:)
        specs = Preflight.gemspecs(root)
        Preflight.raise_error("no gemspecs found") if specs.empty?

        specs.map { |spec| validate_one(spec, package_dir:, version:) }
      end

      def validate_one(spec, package_dir:, version:)
        path = File.join(package_dir, "#{spec.name}-#{version}.gem")
        Preflight.raise_error("missing package: #{path}") unless File.file?(path)

        archive = load_archive(path, spec, version)
        validate_contents!(archive, path)

        {name: spec.name, path:, sha256: Digest::SHA256.file(path).hexdigest}
      rescue StandardError => e
        raise e if e.is_a?(Preflight::Error)

        Preflight.raise_error("#{path}: #{e.message}")
      end

      def validate_contents!(archive, path)
        files = archive.files
        Preflight.raise_error("empty package: #{path}") if files.empty?
        validate_paths!(files, path)
        validate_required_files!(files, path)
      end

      def load_archive(path, spec, version)
        archive = Gem::Package.new(path).spec
        Preflight.raise_error("malformed package name: #{path}") unless archive.name == spec.name
        Preflight.raise_error("malformed package version: #{path}") unless archive.version.to_s == version

        archive
      end

      def validate_paths!(files, path)
        invalid = files.grep(%r{\A(?:/|\.\./)|(?:^|/)\.agents(?:/|$)|(?:^|/)AGENTS\.md\z})
        Preflight.raise_error("invalid package contents in #{path}: #{invalid.join(", ")}") unless invalid.empty?
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
end

# rubocop:disable Metrics/BlockLength

Rake::FileUtilsExt.verbose_flag = false

task_label = -> (string) { "\e[1;33m#{string}\e[0m" }

def require_clean_worktree
  output, error, status = Open3.capture3("git", "status", "--short")
  raise "Cannot inspect git status: #{error}" unless status.success?
  raise "Worktree is not clean:\n#{output}" unless output.empty?
end

def build_docs(rootdir)
  rm_rf(::File.join(rootdir, ".cache/ruby/doc/api"))
  rm_rf(::File.join(rootdir, ".cache/ruby/yardoc"))
  sh("yard", "doc", "--fail-on-warning")
end

def require_complete_docs
  output, error, status = Open3.capture3("yard", "stats", "--list-undoc")
  raise "YARD stats failed: #{error}" unless status.success?

  undocumented = output.lines.select { it.match?(/\(\s*[1-9]\d* undocumented\)/) }
  raise "Undocumented public API objects:\n#{output}" unless undocumented.empty?

  warn(output)
end

def require_private_pages_hidden(rootdir)
  pages = %w[
    Sevgi/Executor/Scope.html
    Sevgi/Executor/Source.html
    Sevgi/Geometry/Equation/Quadratic.html
    Sevgi/Sundries/Export/Renderer.html
  ]
    .map { ::File.join(rootdir, ".cache/ruby/doc/api", it) }
  present = pages.select { ::File.exist?(it) }
  raise "Private API pages are exposed:\n#{present.join("\n")}" unless present.empty?
end

ORDER = %w[
  function
  geometry
  graphics
  standard
  derender
  sundries
  toplevel
  showcase
].freeze

rootdir = File.expand_path(__dir__)
version = File.read("#{rootdir}/VERSION").strip
pkgdir = File.expand_path(ENV.fetch("PKGDIR", "pkg"), rootdir)
projects = Hash[
  *::Dir[::File.join(rootdir, "*/*.gemspec")]
    .map do |file|
      project = ::File.dirname(file).delete_prefix("#{rootdir}/")
      [project, ::File.basename(file, ".*")]
    end
    .flatten
]
names = (ORDER & projects.keys) + (projects.keys - ORDER).sort
tracked_libs = names
  .flat_map { |project| ::Dir[::File.join(rootdir, project, "lib/**/*.rb")] }
  .map do |file|
    ::File.expand_path(file)
  end
  .sort

COVERAGE_FLOORS = {
  branch: 78.0,
  line: 94.0
}.freeze

def coverage_percent(covered, total)
  total.zero? ? 100.0 : ((covered * 100.0) / total)
end

def coverage_totals(report)
  data = JSON.parse(::File.read(report))
  totals = {
    branch: {covered: 0, total: 0},
    line: {covered: 0, total: 0}
  }

  data.fetch("coverage").each_value do |file|
    file.fetch("lines").each do |coverage|
      next unless coverage.is_a?(::Integer)

      totals[:line][:covered] += 1 if coverage.positive?
      totals[:line][:total] += 1
    end

    file.fetch("branches", []).each do |branch|
      coverage = branch.fetch("coverage")
      next unless coverage.is_a?(::Integer)

      totals[:branch][:covered] += 1 if coverage.positive?
      totals[:branch][:total] += 1
    end
  end

  totals.transform_values { |total| coverage_percent(total.fetch(:covered), total.fetch(:total)) }
end

def coverage_files(report)
  data = JSON.parse(::File.read(report))

  data.fetch("coverage").keys.map { |file| ::File.expand_path(file) }.sort
end

def require_coverage_files(report, expected)
  missing = expected - coverage_files(report)
  raise "Coverage report is missing tracked files:\n#{missing.join("\n")}" unless missing.empty?
end

def require_coverage_floors(totals, floors)
  failures = floors.filter_map do |criterion, floor|
    total = totals.fetch(criterion)
    "#{criterion}: #{format("%.2f", total)}% < #{format("%.2f", floor)}%" if total < floor
  end

  raise "Coverage below floor:\n#{failures.join("\n")}" unless failures.empty?
end

directory(pkgdir)

names.each do |project|
  package = projects.fetch(project)

  namespace(project) do
    gem = "#{pkgdir}/#{package}-#{version}.gem"
    gemspec = "#{package}.gemspec"

    %i[lint test].each do |tn|
      desc("#{tn.capitalize} #{project.capitalize}")
      task(tn) do |t|
        warn("#{task_label.call(t)}")
        Dir.chdir(::File.join(rootdir, project)) do
          sh("rake", tn.to_s)
        end

        warn("")
      end
    end

    desc("Package #{package}")
    task(package: [pkgdir]) do |t|
      warn("#{task_label.call(t)}")
      Dir.chdir(::File.join(rootdir, project)) do
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

namespace(:release) do
  desc("Guard release ref and versions")
  task(:guard) do
    SevgiRelease::Preflight.guard!(root: rootdir, ref: ENV.fetch("GITHUB_REF"))
  end

  desc("Validate built release archives")
  task(:verify) do
    SevgiRelease::Preflight.preflight!(root: rootdir, ref: ENV.fetch("GITHUB_REF"), package_dir: pkgdir)
  end

  desc("Check release workspace")
  task(:preflight) do
    require_clean_worktree
    branch, error, status = Open3.capture3("git", "branch", "--show-current")
    raise "Cannot inspect git branch: #{error}" unless status.success?
    raise "Release requires the main branch" unless branch.strip == "main"

    Rake::Task[:build].invoke
    manifest = SevgiRelease::Preflight.preflight!(
      root: rootdir,
      ref: "refs/heads/main",
      package_dir: pkgdir
    )
    checksum_file = ::File.join(pkgdir, "SHA256SUMS")
    ::File.write(
      checksum_file,
      manifest
        .fetch(:archives)
        .map { |archive| "#{archive.fetch(:sha256)}  #{::File.basename(archive.fetch(:path))}" }
        .join("\n") +
        "\n"
    )
    SevgiRelease::Preflight.assert_checksums!(
      package_dir: pkgdir,
      archives: manifest.fetch(:archives),
      path: checksum_file
    )
  end
end

desc("Release all")
task(:release => "release:preflight") do
  manifest = SevgiRelease::Preflight.preflight!(root: rootdir, ref: "refs/heads/main", package_dir: pkgdir)
  SevgiRelease::Preflight.assert_checksums!(package_dir: pkgdir, archives: manifest.fetch(:archives))
  manifest.fetch(:archives).each { |archive| sh("gem", "push", archive.fetch(:path)) }
  require_clean_worktree
end

desc("Build API documentation")
task(:doc) do
  build_docs(rootdir)
end

namespace(:doc) do
  desc("Check API documentation")
  task(:check) do
    build_docs(rootdir)
    require_complete_docs
    require_private_pages_hidden(rootdir)
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
    report = ::File.join(rootdir, ".cache/ruby/coverage/coverage.json")
    require_coverage_files(report, tracked_libs)
    totals = coverage_totals(report)
    require_coverage_floors(totals, COVERAGE_FLOORS)
    warn("Line coverage: #{format("%.2f", totals.fetch(:line))}%")
    warn("Branch coverage: #{format("%.2f", totals.fetch(:branch))}%")
  end
end

namespace(:clean) do
  desc("Clean coverage reports")
  task(:coverage) do
    rm_rf(::File.join(rootdir, ".cache/ruby/coverage"))
  end
end

desc("Bump versions")
task(:bump) do
  if ENV["version"]
    ::File.write("#{rootdir}/VERSION", version = ENV["version"])
  end

  ::Dir[::File.join(rootdir, "*/**/version.rb")].each do |source|
    ::File.write(
      source,
      ::File.read(source).gsub(/^(\s*)VERSION(\s*)= .*?$/, "\\1VERSION = \"#{version}\"")
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
