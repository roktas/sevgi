+++
title = "Getting Started"
weight = 1
[extra]
group = "Start"
+++

Sevgi creates SVG with Ruby. It uses one drawing vocabulary in executable `.sevgi` scripts and in ordinary Ruby
libraries. The host changes how you qualify a few entry points; the SVG block itself does not change.

## Your first drawing

In library code, `SVG` is both the document builder and the facade for SVG-related operations:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 80, height: 50, margins: 5

drawing = SVG :minimal, canvas do
  rect width: canvas.inner.width, height: canvas.inner.height, rx: 4, fill: "linen"
  circle cx: 15, cy: 15, r: 8, fill: "tomato"
  text "Hello", x: 28, y: 18, "font-size": 8
end

puts drawing.Render
```

Three similar-looking forms have distinct jobs:

| Form | Meaning |
| --- | --- |
| `SVG(...)` | build an SVG document |
| `SVG.Canvas(...)` | call the capitalized `Canvas` operation on the SVG facade |
| `SVG::Canvas` | refer to the Ruby type returned by that operation |

In a `.sevgi` script, facade operations become bare DSL words: write `Canvas(...)` instead of `SVG.Canvas(...)`.
The `SVG(...)` document builder and everything inside its block keep the same spelling. The
[One DSL, Two Hosts](@/usage.md) guide shows the two complete forms side by side.

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

[One DSL, Two Hosts](@/usage.md) compares executable scripts with library calls. Both use the same documents and
drawing DSL.

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
