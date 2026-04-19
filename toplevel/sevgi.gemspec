# frozen_string_literal: true

version = File.read(File.expand_path("../VERSION", __dir__)).strip

Gem::Specification.new do |s|
  s.name                              = "sevgi"
  s.author                            = "Recai Oktaş"
  s.email                             = "roktas@gmail.com"
  s.license                           = "GPL-3.0-or-later"
  s.version                           = version
  s.summary                           = "Toolkit for creating SVG content programmatically with Ruby."
  s.description                       = "Provides a scriptable DSL with utilities for creating SVG content with Ruby."
  s.homepage                          = "https://sevgi.roktas.dev"
  s.files                             = Dir["../LICENSE", "README.md", "lib/**/*"]
  s.executables                       = [ "sevgi" ]
  s.required_ruby_version             = ">= 3.4.0-preview1"
  s.metadata["changelog_uri"]         = "https://github.com/roktas/sevgi/blob/main/CHANGELOG.md"
  s.metadata["source_code_uri"]       = "https://github.com/roktas/sevgi"
  s.metadata["bug_tracker_uri"]       = "https://github.com/roktas/sevgi/issues"
  s.metadata["rubygems_mfa_required"] = "true"

  s.add_dependency "sevgi-derender", version
  s.add_dependency "sevgi-function", version
  s.add_dependency "sevgi-geometry", version
  s.add_dependency "sevgi-graphics", version
  s.add_dependency "sevgi-standard", version
  s.add_dependency "sevgi-sundries", version
end
