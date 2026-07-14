# Sevgi Geometry

Sevgi Geometry provides the small set of geometric values and operations used by Sevgi drawings.

## Install

```sh
gem install sevgi-geometry
```

## Require

```ruby
require "sevgi/geometry"
```

## Example

```ruby
rect = Sevgi::Geometry::Rect[3, 5]
rect.box.width
```

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies Ruby 3.4.0 and the current development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs only Ruby and its Ruby dependencies.

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi-geometry
- Source: https://github.com/roktas/sevgi/tree/main/geometry
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
