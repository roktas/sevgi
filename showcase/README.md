# Sevgi Showcase

Sevgi Showcase packages the executable examples, their SVG output, and support code for the documentation site.

## Install

```sh
gem install sevgi-showcase
```

## Contents

The gem is an asset package rather than a runtime API. It contains the executable `.sevgi` examples, their expected
SVG output, and private build support used by the documentation site.

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

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

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-showcase>
- Source: <https://github.com/roktas/sevgi/tree/main/showcase>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
