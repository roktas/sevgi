# frozen_string_literal: true

$LOAD_PATH.push(File.expand_path("lib", __dir__))

require "sevgi/version"

Gem::Specification.new do |s|
  s.name                              = "sevgi"
  s.author                            = "Recai Oktaş"
  s.email                             = "roktas@gmail.com"
  s.license                           = "GPL-3.0-or-later"
  s.version                           = Sevgi::VERSION
  s.summary                           = "Toolkit for Creating SVG Content Programmatically with Ruby"
  s.description                       = "Toolkit for Creating SVG Content Programmatically with Ruby"
  s.homepage                          = "https://sevgi.roktas.dev"
  s.files                             = Dir["CHANGELOG.md", "LICENSE", "README.md", "lib/**/*"]
  s.executables                       = ["sevgi"]
  s.require_paths                     = ["lib"]
  s.required_ruby_version             = ">= 3.2.2"
  s.metadata["changelog_uri"]         = "https://github.com/roktas/sevgi/blob/main/CHANGELOG.md"
  s.metadata["source_code_uri"]       = "https://github.com/roktas/sevgi"
  s.metadata["bug_tracker_uri"]       = "https://github.com/roktas/sevgi/issues"
  s.metadata["rubygems_mfa_required"] = "true"
end
