# Sevgi Showcase

Executable examples, rendered outputs, and documentation-site support.

## Install

```sh
gem install sevgi-showcase
```

## Require

```ruby
require "sevgi/showcase"
```

## Example

```ruby
suite = Sevgi::Test::Suite.new("srv")
suite.valids.map(&:name)
```

## Native prerequisites

Showcase examples use the top-level Sevgi stack. Native export prerequisites match `sevgi-sundries` only when examples
or local workflows use PDF/PNG export.

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi-showcase
- Source: https://github.com/roktas/sevgi/tree/main/showcase
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
