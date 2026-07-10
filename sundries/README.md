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

Basic ruler, grid, and tile helpers need only Ruby dependencies. Installing `sevgi-sundries` does not install native
export gems.

PDF/PNG export helpers load the optional Ruby gems `cairo`, `rsvg2`, and `hexapdf` only when export is used. Install
their system libraries and gems separately:

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
- API documentation: https://www.rubydoc.info/gems/sevgi-sundries
- Source: https://github.com/roktas/sevgi/tree/main/sundries
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
