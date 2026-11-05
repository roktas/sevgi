# Sevgi Sundries

Sevgi Sundries contains shared layout objects and optional export tools.

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
x = Sevgi::Sundries::Ruler.new(brut: 80, unit: 1, multiple: 10, margins: [5])
y = Sevgi::Sundries::Ruler.new(brut: 50, unit: 1, multiple: 10, margins: [5])
grid = Sevgi::Sundries::Grid[x, y]

grid.x.major.lines.size # => 5
grid.canvas.margin.to_a # => [5.0, 5.0, 5.0, 5.0]
```

Rulers, grids, and tiles are inspectable Ruby values. They create no SVG elements by themselves. Pass their geometry
to Sevgi Graphics when the document needs it.

## Prepared PDF export

Sevgi uses the native Mainz CLI for SVG sources with an Imprint declaration or a PNG preview.
Mainz receives private temporary files through argument arrays and publishes one PDF with the declared metadata and paint controls.
Successful preparation replaces the destination atomically.
Parallel calls use separate temporary directories and share no producer state.

```ruby
require "sevgi/sundries"

Sevgi::Sundries::Export.call(svg, "drawing.pdf", declaration: declaration)
Sevgi::Sundries::Export.call(svg, "prepared.pdf", declaration: declaration, fallback: false)
Sevgi::Sundries::Imprint.call(svg, "prepared.pdf", declaration: declaration)
Sevgi::Sundries::Imprint.available?
```

`declaration` is a JSON-compatible Hash. `drawing.Imprint` returns its deeply frozen Hash representation.
The declaration's optional `page` object carries `name` and `tags`. The Imprint DSL builds it with `Page`.
Use `preview: png_bytes` for a separate PNG thumbnail. Page annotations and previews also work without editable paint;
the `targets` and `parameters` maps are then empty.
The default `fallback: true` warns and uses ordinary PDF export if Mainz cannot prepare the document.
Ordinary PDF export omits declared page metadata, editable controls, and previews.
`fallback: false` raises `Sevgi::Sundries::Imprint::Error` if preparation fails.
A document without a declaration or preview uses ordinary export.
`Imprint.call` always requires a successful Mainz export and uses the same input validation.
Invalid arguments and filesystem failures remain errors in both modes.
Interrupts cancel export without fallback.
CSS insertion and the source callback run once, including after a fallback.

Mainz is optional. Prepared export requires a native `mainz` executable on `PATH`
with support for the `imprint` command and its `--preview` option.

Prepared export invokes the CLI without the `cairo`, `rsvg2`, and `hexapdf` Ruby gems.
Ordinary PDF/PNG export and PDF stamping retain their optional Ruby dependencies.
`Imprint.fingerprint` returns the executable digest and native dependency report for output caches, or nil when Mainz is absent.

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

## Native prerequisites

Basic ruler, grid, and tile helpers need only Ruby dependencies. Installing `sevgi-sundries` does not install native
export gems.

The `a5_on_a4` helpers require the `pdfcpu` command. They use its built-in defaults without personal pdfcpu configuration.

Ordinary PDF/PNG export helpers load the optional Ruby gems `cairo`, `rsvg2`, and `hexapdf` only when export is used. Install
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

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-sundries>
- Source: <https://github.com/roktas/sevgi/tree/main/sundries>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
