# Sevgi Sundries

Helper objects and export tools for Sevgi drawings.

## Install

```sh
gem install sevgi-sundries
```

## Require

```ruby
require "sevgi/sundries"
```

## Example

```ruby
rect = Sevgi::Geometry::Rect[3, 5]
tile = Sevgi::Sundries::Tile.new(rect)
tile.box.height
```

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies Ruby 3.4 and the current development Ruby from `.ruby-version`.

## Native prerequisites

Basic ruler, grid, and tile helpers need only Ruby dependencies. PDF/PNG export helpers require Cairo and librsvg
system libraries with development headers available to the `cairo` and `rsvg2` gems.

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi-sundries
- Source: https://github.com/roktas/sevgi/tree/main/sundries
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
