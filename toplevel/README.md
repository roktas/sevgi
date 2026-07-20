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
SVG :minimal do
  rect width: 3, height: 5
end.call
```

## Executables

```sh
sevgi drawing.sevgi
igsev drawing.svg
```

Both commands read standard input when the file is omitted or `-`. For `sevgi`, implicit `Save`, `PDF`, and `PNG`
destinations use `output` as the input name; use `--as NAME` to choose another basename:

```sh
sevgi --as badge < drawing.sevgi
igsev < drawing.svg > normalized.svg
```

`NAME` cannot include a directory. An explicit output path or `default:` argument in the script remains authoritative.
With a file operand, `--as` keeps the file's source directory so relative `Load` calls continue to resolve there.

`sevgi --skill` prints the validated path of the matching packaged agent skill. See the
[Appendix documentation](https://github.com/roktas/sevgi/tree/main/appendix) for installation guidance.

`igsev` converts an SVG file to Sevgi source, evaluates it with the complete DSL, and prints the resulting normalized
SVG. Use `igves` from `sevgi-derender` when the generated Sevgi source itself is the desired output.

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

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

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi>
- Source: <https://github.com/roktas/sevgi/tree/main/toplevel>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
