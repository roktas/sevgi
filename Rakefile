# frozen_string_literal: true

ENV["PATH"] += ":#{__dir__}/bin"

require "rubocop/rake_task"
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = [ "--display-cop-names" ]
end

desc "Lint code"
task lint: :rubocop

require "rake/testtask"
Rake::TestTask.new(:"test:unit") do |t|
  t.test_files = FileList["test/**/*_test.rb"].exclude(/(^[._]|integration)/)
end
Rake::TestTask.new(:"test:integration") do |t|
  t.test_files = [ "test/integration_test.rb" ]
end

desc "Run all tests"
task test: %i[test:unit test:integration]

require "rubygems/tasks"
Gem::Tasks.new(console: false) do |tasks|
  tasks.push.host = ENV["RUBYGEMS_HOST"] || Gem::DEFAULT_HOST
end

desc "Build site examples"
task :"site:examples" do
  require "sevgi/internal/minitest"

  Sevgi::Test::Suite.new("srv/examples").valids.map(&:file).each do |script|
    sh script
  end
end

desc "Build site"
task :"site:build" do
  Dir.chdir("srv") { sh "zola build" }
end

desc "Serve site"
task :"site:serve" do
  Dir.chdir("srv") { sh "zola serve" }
end

task serve: [ :"site:serve" ]

require "rake/clean"
CLEAN.include("*.gem", "pkg", "coverage", "srv/public")

task default: [ :test ]

task all: %i[lint test]
