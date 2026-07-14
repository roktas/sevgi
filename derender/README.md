# Sevgi Derender

Sevgi Derender converts SVG or XML back into Sevgi DSL source.

## Install

```sh
gem install sevgi-derender
```

## Require

```ruby
require "sevgi/derender"
```

## Example

```ruby
source = "<svg><rect width=\"3\" height=\"5\"/></svg>"
Sevgi::Derender.derender(source)
```

## Executable

```sh
igves drawing.svg
```

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies Ruby 3.4.0 and the current development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs no native libraries of its own. Nokogiri may use platform packages depending on the target Ruby platform.

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi-derender
- Source: https://github.com/roktas/sevgi/tree/main/derender
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
