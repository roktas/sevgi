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

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies Ruby 3.4.0 and the current development Ruby from `.ruby-version`.

## Native prerequisites

Showcase examples use the top-level Sevgi stack. SVG-only examples need no native export gems.

PDF/PNG export workflows match `sevgi-sundries` and require the optional Ruby gems `cairo`, `rsvg2`, and `hexapdf`.
On Debian/Ubuntu:

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
- API documentation: https://www.rubydoc.info/gems/sevgi-showcase
- Source: https://github.com/roktas/sevgi/tree/main/showcase
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
