# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(File.expand_path(".ruby-version", __dir__)).strip

group :sevgi do
  gem "sevgi-derender", path: "derender"
  gem "sevgi-function", path: "function"
  gem "sevgi-geometry", path: "geometry"
  gem "sevgi-graphics", path: "graphics"
  gem "sevgi-showcase", path: "showcase"
  gem "sevgi-standard", path: "standard"
  gem "sevgi-sundries", path: "sundries"

  gem "sevgi",          path: "toplevel"
end

group :test, :development do
  gem "bundler", "~> 4.0"
  gem "minitest", "~> 5.27"
  gem "minitest-focus", "~> 1.4"
  gem "minitest-reporters", "~> 1.7"
  gem "rake"
end

group :development do
  gem "rubocop-md"
  gem "rubocop-packaging"
  gem "rubocop-rails-omakase"
  gem "rubocop-rake"
  gem "ruby-lsp"
end
