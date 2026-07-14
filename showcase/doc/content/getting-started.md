+++
title = "Getting Started"
weight = 1
[extra]
group = "Start"
+++

Sevgi creates SVG with Ruby. The quickest way in is a `.sevgi` script. Write ordinary Ruby, open an `SVG` block, and
finish with `Save` or `Out`.

The tabs below come from the same files that the test suite runs. The Ruby tab contains the script; the SVG tab contains
its output.

{{ tabs(base="meter-face", dir="../showcase") }}

## Run an example

From a checkout, run the showcase scripts with Bundler:

```bash
bundle exec showcase/srv/meter-face.sevgi
```

The script writes `showcase/srv/meter-face.svg` because it ends with `Save`. To write SVG to standard output instead,
use `Out` in the script.

[Choose a Mode](@/usage.md) compares executable scripts with library calls. Both use the same documents and drawing DSL.

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

`SVG` accepts a document profile. `:minimal` omits the XML declaration and produces compact output. The default profile
writes a complete SVG document, while `:inkscape` adds editor-specific namespaces and helpers.

{{ tabs(base="snow-flake", dir="../showcase") }}
