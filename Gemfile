# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(File.expand_path(".ruby-version", __dir__)).strip

gemspec path: "external"

group :sevgi do
  gem "sevgi-standard", path: "standard"
  gem "sevgi-geometry", path: "geometry"
  gem "sevgi-graphics", path: "graphics"
end

group :test, :development do
  gem "bundler"
  gem "minitest"
  gem "minitest-focus", ">= 1.2.1"
  gem "minitest-reporters", ">= 1.4.3"
  gem "rake"
end

group :development do
  gem "rubocop-md"
  gem "rubocop-packaging"
  gem "rubocop-rails-omakase"
  gem "rubocop-rake"
  gem "ruby-lsp"
end
