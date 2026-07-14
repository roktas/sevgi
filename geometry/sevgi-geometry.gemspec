# frozen_string_literal: true

version = File.read(File.expand_path("../VERSION", __dir__)).strip

Gem::Specification.new do |s|
  s.name = "sevgi-geometry"
  s.author = "Recai Oktaş"
  s.email = "roktas@gmail.com"
  s.license = "GPL-3.0-or-later"
  s.version = version
  s.summary = "Geometry values and operations for Sevgi drawings."
  s.description = "Models the points, lines, shapes, and transforms used by the DSL."
  s.homepage = "https://sevgi.roktas.dev"
  s.files = Dir.chdir(__dir__) { Dir["CHANGELOG.md", "LICENSE", "README.md", "lib/**/*"] }
  s.required_ruby_version = ">= 3.4.0"
  s.metadata["changelog_uri"] = "https://github.com/roktas/sevgi/blob/main/CHANGELOG.md"
  s.metadata["source_code_uri"] = "https://github.com/roktas/sevgi"
  s.metadata["bug_tracker_uri"] = "https://github.com/roktas/sevgi/issues"
  s.metadata["rubygems_mfa_required"] = "true"

  s.add_dependency("sevgi-function", version)
end
