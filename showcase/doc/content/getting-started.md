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

For released versions, install the top-level gem:

```bash
gem install sevgi
```

This installs the `sevgi` executable and the standard components used by scripts.

SVG-only scripts do not need native export gems. If a script writes PDF or PNG through Sevgi's native export helpers,
install the optional native export stack separately. On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y libcairo2-dev libgdk-pixbuf-2.0-dev libgirepository1.0-dev libglib2.0-dev librsvg2-dev pkg-config
gem install cairo rsvg2 hexapdf
```

On macOS with Homebrew:

```bash
brew install cairo gdk-pixbuf gobject-introspection librsvg pkg-config
gem install cairo rsvg2 hexapdf
```

## Choose a document profile

`SVG` accepts a document profile. `:minimal` produces compact output, `:default` writes a standalone SVG document,
`:html` is suitable for embedding, and `:inkscape` adds editor metadata and helpers. See the
[document-profile matrix](@/svg.md#document-profiles) for the exact capabilities.

{{ tabs(base="snowflake", dir="../showcase") }}
