# frozen_string_literal: true

version = File.read(File.expand_path("../VERSION", __dir__)).strip

Gem::Specification.new do |s|
  s.name                              = "sevgi-showcase"
  s.author                            = "Recai Oktaş"
  s.email                             = "roktas@gmail.com"
  s.license                           = "GPL-3.0-or-later"
  s.version                           = version
  s.summary                           = "Documents and examples for the Sevgi toolkit."
  s.description                       = "Provides documents and examples to demonstrate the Sevgi toolkit."
  s.homepage                          = "https://sevgi.roktas.dev"
  s.files                             = Dir["../LICENSE", "README.md", "srv/examples/**/*", "lib/**/*"]
  s.required_ruby_version             = ">= 3.4.0-preview1"
  s.metadata["changelog_uri"]         = "https://github.com/roktas/sevgi/blob/main/CHANGELOG.md"
  s.metadata["source_code_uri"]       = "https://github.com/roktas/sevgi"
  s.metadata["bug_tracker_uri"]       = "https://github.com/roktas/sevgi/issues"
  s.metadata["rubygems_mfa_required"] = "true"

  s.add_dependency "sevgi", version
end
