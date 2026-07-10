# Sevgi Graphics

Core SVG DSL, document profiles, and rendering behavior.

## Install

```sh
gem install sevgi-graphics
```

## Require

```ruby
require "sevgi/graphics"
```

## Example

```ruby
doc = Sevgi::Graphics.SVG(:minimal) { rect(width: 3, height: 5) }
doc.call
```

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies Ruby 3.4.0 and the current development Ruby from `.ruby-version`.

## Native prerequisites

None beyond Ruby and this gem's Ruby dependencies.

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi-graphics
- Source: https://github.com/roktas/sevgi/tree/main/graphics
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
