# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

Rake::FileUtilsExt.verbose_flag = false

def yellow(string) = "\e[1;33m#{string}\e[0m"

rootdir  = File.expand_path(__dir__)
version  = File.read("#{rootdir}/VERSION").strip
projects = Hash[*
  ::Dir["*/*.gemspec"].map do |file|
    [::File.dirname(file), ::File.basename(file, ".*")]
  end.flatten
]

directory "pkg"

projects.each do |project, package|
  namespace project do
    gem     = "pkg/#{package}-#{version}.gem"
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
    task :package => %w[ pkg ] do |t|
      warn "#{yellow(t)}"
      Dir.chdir(project) do
        sh <<~CMD
          rake package && gem build #{gemspec} && mv #{package}-#{version}.gem #{rootdir}/pkg/ && rm -rf pkg
        CMD
      end
      warn ""
    end

    desc "Build #{package}"
    task build: %i[ clean package ]

    desc "Push #{package}"
    task push: :build do |t|
      warn "#{yellow(t)}"
      sh "gem push #{gem}"
      warn ""
    end
  end
end

%i[ build lint push test ].each do |tn|
  desc "#{tn.capitalize} all"
  task tn => projects.keys.map { |project| "#{project}:#{tn}" }
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
