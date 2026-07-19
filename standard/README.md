# Sevgi Standard

Sevgi Standard supplies the SVG element and attribute data used by validation.

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

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs only Ruby and its Ruby dependencies.

## Links

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-standard>
- Source: <https://github.com/roktas/sevgi/tree/main/standard>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
