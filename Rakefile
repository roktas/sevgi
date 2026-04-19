# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

Rake::FileUtilsExt.verbose_flag = false

def yellow(string) = "\e[1;33m#{string}\e[0m"

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

rootdir  = File.expand_path(__dir__)
version  = File.read("#{rootdir}/VERSION").strip
projects = Hash[*
  ::Dir["*/*.gemspec"].map do |file|
    [ ::File.dirname(file), ::File.basename(file, ".*") ]
  end.flatten
]
names = (ORDER & projects.keys) + (projects.keys - ORDER).sort

directory "pkg"

names.each do |project|
  package = projects.fetch(project)

  namespace project do
    gem     = "#{rootdir}/pkg/#{package}-#{version}.gem"
    gemspec = "#{package}.gemspec"

    %i[ lint test ].each do |tn|
      desc "#{tn.capitalize} #{project.capitalize}"
      task tn do |t|
        warn "#{yellow(t)}"
        Dir.chdir(project) do
          sh "rake #{tn}"
        end
        warn ""
      end
    end

    desc "Package #{package}"
    task package: %w[ pkg ] do |t|
      warn "#{yellow(t)}"
      Dir.chdir(project) do
        sh "gem build #{gemspec} --output #{gem}"
      end
      warn ""
    end

    desc "Build #{package}"
    task build: :package

    desc "Release #{package}"
    task release: :build do |t|
      warn "#{yellow(t)}"
      sh "gem push #{gem}"
      warn ""
    end
  end
end

%i[ build lint release test ].each do |tn|
  desc "#{tn.capitalize} all"
  task tn => names.map { |project| "#{project}:#{tn}" }
end

desc "Bump versions"
task :bump do
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

desc "Clean all"
task :clean do
  rm_rf "pkg"
end

desc "Make (almost) all"
task all:     %i[ lint test ]

task default: :test
