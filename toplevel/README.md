# Sevgi

The `sevgi` gem provides the top-level API and the `.sevgi` script runner.

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

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies Ruby 3.4.0 and the current development Ruby from `.ruby-version`.

## Native prerequisites

The top-level gem installs Sevgi's standard components without native export gems. SVG-only scripts need no native
packages beyond the standard Ruby dependencies.

PDF/PNG export helpers come from `sevgi-sundries` and lazily load the optional Ruby gems `cairo`, `rsvg2`, and
`hexapdf`. On Debian/Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y libcairo2-dev libgdk-pixbuf-2.0-dev libgirepository1.0-dev libglib2.0-dev librsvg2-dev pkg-config
gem install cairo rsvg2 hexapdf
```

On macOS with Homebrew:

```sh
brew install cairo gdk-pixbuf gobject-introspection librsvg pkg-config
gem install cairo rsvg2 hexapdf
```

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi
- Source: https://github.com/roktas/sevgi/tree/main/toplevel
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
