# Sevgi Standard

SVG element, attribute, and conformance data used by Sevgi validation.

## Install

```sh
gem install sevgi-standard
```

## Require

```ruby
require "sevgi/standard"
```

## Example

```ruby
Sevgi::Standard.element?(:rect)
Sevgi::Standard.attribute?(:width)
```

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies Ruby 3.4.0 and the current development Ruby from `.ruby-version`.

## Native prerequisites

None beyond Ruby and this gem's Ruby dependencies.

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi-standard
- Source: https://github.com/roktas/sevgi/tree/main/standard
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
