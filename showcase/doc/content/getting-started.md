+++
title = "Getting Started"
weight = 1
[extra]
group = "Start"
+++

Sevgi creates SVG with Ruby. A drawing can be an executable `.sevgi` script or a value built inside another Ruby
application.

## Script and library modes

Use script mode when the drawing is the program, such as a generated asset or build job. The runner supplies Sevgi's
entry points, and the script usually writes or prints its result:

```ruby
#!/usr/bin/env -S ruby -S sevgi

canvas = Canvas width: 24, height: 24, unit: :px

SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save "badge.svg"
```

Use library mode when an application owns the drawing and decides where its rendered string goes:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 24, height: 24, unit: :px

drawing = SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end

File.write "badge.svg", drawing.Render
```

The `SVG` block is the same in both modes. Operations around it are bare words in a script and capitalized methods on
the `SVG` facade in library code:

| Role | `.sevgi` script | Ruby library |
| --- | --- | --- |
| Build a document | `SVG(...)` | `SVG(...)` |
| Create a canvas | `Canvas(...)` | `SVG.Canvas(...)` |
| Refer to the canvas type | `SVG::Canvas` | `SVG::Canvas` |

The script passes its document to `Save`. The application keeps the document and passes its `Render` result to ordinary
Ruby code. [Script Mode](@/script-mode.md) and [Library Mode](@/library-mode.md) cover each form in detail.

## See a complete drawing

The tabs below come from the same files that the test suite runs. The Ruby tab contains the script; the SVG tab contains
its output.

{{ tabs(base="meter", dir="../showcase") }}

## Run an example

From a checkout, run the showcase scripts with Bundler:

```bash
bundle exec showcase/srv/meter.sevgi
```

The script writes `showcase/srv/meter.svg` because it ends with `Save`. To write SVG to standard output instead,
use `Out` in the script.

## Install the CLI

For the complete command-line toolkit, install Sevgi through Homebrew on macOS or Linux:

```bash
brew install roktas/tap/sevgi
```

This installs the `sevgi` executable, Ruby, the native PDF and PNG export stack, and the headless pdfcpu and Poppler
tools. Inkscape remains an optional external backend.

When Sevgi is a dependency of a Ruby application, add the umbrella gem to its bundle instead:

```ruby
gem "sevgi"
```

SVG-only library use needs no native graphics packages. Applications that install gems directly and use PDF or PNG
export must provide the optional `cairo`, `rsvg2`, and `hexapdf` gems and their system libraries themselves. See the
[`sevgi-sundries` package guide](https://github.com/roktas/sevgi/tree/main/sundries) for those prerequisites. The
[repository README](https://github.com/roktas/sevgi) lists focused component gems for smaller dependency surfaces.

The full installation also packages Sevgi's agent skill. Run `sevgi --skill` to locate it, then follow the
[Appendix setup guide](https://github.com/roktas/sevgi/tree/main/appendix).

## Choose a document profile

`SVG` accepts a document profile. `:minimal` produces compact output, `:default` writes a standalone SVG document,
`:html` is suitable for embedding, and `:inkscape` adds editor metadata and helpers. See the
[document-profile matrix](@/svg.md#document-profiles) for the exact capabilities.

{{ tabs(base="snowflake", dir="../showcase") }}
