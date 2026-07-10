# frozen_string_literal: true

require "json"
require "open3"

require_relative "script/release"

# rubocop:disable Metrics/BlockLength

Rake::FileUtilsExt.verbose_flag = false

def yellow(string) = "\e[1;33m#{string}\e[0m"

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
        warn("#{yellow(t)}")
        Dir.chdir(::File.join(rootdir, project)) do
          sh("rake", tn.to_s)
        end

        warn("")
      end
    end

    desc("Package #{package}")
    task(package: [pkgdir]) do |t|
      warn("#{yellow(t)}")
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
    SevgiRelease::Preflight.validate_checksums!(
      package_dir: pkgdir,
      archives: manifest.fetch(:archives),
      path: checksum_file
    )
  end
end

desc("Release all")
task(:release => "release:preflight") do
  manifest = SevgiRelease::Preflight.preflight!(root: rootdir, ref: "refs/heads/main", package_dir: pkgdir)
  SevgiRelease::Preflight.validate_checksums!(package_dir: pkgdir, archives: manifest.fetch(:archives))
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
