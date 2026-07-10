# Sevgi

Top-level API and `.sevgi` script runner.

## Install

```sh
gem install sevgi
```

## Require

```ruby
require "sevgi"
```

## Example

```ruby
SVG(:minimal) do
  rect(width: 3, height: 5)
end.call
```

## Executable

```sh
sevgi drawing.sevgi
```

## Native prerequisites

The top-level gem installs Sevgi's standard components. Native export helpers come from `sevgi-sundries` and require
Cairo and librsvg system libraries when PDF/PNG export is used.

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi
- Source: https://github.com/roktas/sevgi/tree/main/toplevel
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
