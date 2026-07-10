# frozen_string_literal: true

require "English"
require "json"

# rubocop:disable Metrics/BlockLength

Rake::FileUtilsExt.verbose_flag = false

def yellow(string) = "\e[1;33m#{string}\e[0m"

def released?(package, version)
  output = `gem list --remote --exact --all #{package}`
  raise "Cannot query RubyGems for #{package}" unless $CHILD_STATUS.success?

  output.match?(/\A#{Regexp.escape(package)} \((?=.*\b#{Regexp.escape(version)}\b)/)
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
  *::Dir["*/*.gemspec"]
    .map do |file|
      [::File.dirname(file), ::File.basename(file, ".*")]
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
        Dir.chdir(project) do
          sh("rake #{tn}")
        end

        warn("")
      end
    end

    desc("Package #{package}")
    task(package: [pkgdir]) do |t|
      warn("#{yellow(t)}")
      Dir.chdir(project) do
        sh("gem", "build", gemspec, "--output", gem)
      end

      warn("")
    end

    desc("Build #{package}")
    task(build: :package)

    desc("Release #{package}")
    task(release: :build) do |t|
      warn("#{yellow(t)}")
      if released?(package, version)
        warn("#{package} #{version} is already released")
        warn("")
        next
      end

      sh("gem push #{gem}")
      warn("")
    end
  end
end

%i[build lint release test].each do |tn|
  desc("#{tn.capitalize} all")
  task(tn => names.map { |project| "#{project}:#{tn}" })
end

desc("Build API documentation")
task(:doc) do
  sh("yard", "doc", "--fail-on-warning")
end

namespace(:doc) do
  desc("Check API documentation")
  task(:check) do
    sh("yard", "doc", "--fail-on-warning")
    sh("yard", "stats", "--list-undoc")
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

desc("Bump versions")
task(:bump) do
  if ENV["version"]
    ::File.write("#{rootdir}/VERSION", version = ENV["version"])
  end

  ::Dir["*/**/version.rb"].each do |source|
    ::File.write(
      source,
      ::File.read(source).gsub(/^(\s*)VERSION(\s*)= .*?$/, "\\1VERSION = \"#{version}\"")
    )
  end
end

desc("Clean all")
task(:clean) do
  rm_rf("pkg")
end

desc("Make (almost) all")
task(all: %i[lint test])

task(default: :test)
