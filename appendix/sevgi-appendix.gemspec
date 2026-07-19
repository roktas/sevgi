# frozen_string_literal: true

version = File.read(File.expand_path("../VERSION", __dir__)).strip

Gem::Specification.new do |s|
  s.name = "sevgi-appendix"
  s.author = "Recai Oktaş"
  s.email = "roktas@gmail.com"
  s.license = "GPL-3.0-or-later"
  s.version = version
  s.summary = "Development extras for the Sevgi SVG DSL."
  s.description = "Packages the Sevgi agent skill and RuboCop rules for readable .sevgi source."
  s.homepage = "https://sevgi.roktas.dev"
  s.files = Dir.chdir(__dir__) do
    Dir["CHANGELOG.md", "LICENSE", "README.md", "agents/**/*", "lib/**/*", "rubocop/**/*"]
  end
  s.required_ruby_version = ">= 3.4.0"
  s.metadata["changelog_uri"] = "https://github.com/roktas/sevgi/blob/main/CHANGELOG.md"
  s.metadata["source_code_uri"] = "https://github.com/roktas/sevgi/tree/main/appendix"
  s.metadata["bug_tracker_uri"] = "https://github.com/roktas/sevgi/issues"
  s.metadata["rubygems_mfa_required"] = "true"
  s.metadata["default_lint_roller_plugin"] = "RuboCop::Sevgi::Plugin"
  s.metadata["sevgi_skill_path"] = "agents/skills/sevgi"

  s.add_dependency("lint_roller", "~> 1.1")
  s.add_dependency("rubocop", ">= 1.72.2", "< 2.0")
end
