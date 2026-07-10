+++
title = "Getting Started"
weight = 1
+++

Sevgi creates SVG with Ruby. The recommended entry point is a `.sevgi` script: write Ruby, call the `SVG` DSL word, and
finish with an output method such as `Save` or `Out`.

The examples below are the same scripts used by the showcase test suite. Open the Ruby tab to inspect the source and the
SVG tab to inspect the rendered result.

{{ tabs(base="meter-face", dir="../showcase") }}

## Run An Example

From a checkout, run the showcase scripts with Bundler:

```bash
bundle exec showcase/srv/meter-face.sevgi
```

The script writes `showcase/srv/meter-face.svg` because it ends with `Save`. To write SVG to standard output instead,
use `Out` in the script.

## Install The CLI

For released versions, install the top-level gem:

```bash
gem install sevgi
```

This installs the `sevgi` executable used by `.sevgi` scripts and pulls in the standard components: graphics, geometry,
standard validation, derendering, sundries, and shared functions.

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

## Choose A Document Profile

`SVG` can be called with a document profile. `:minimal` emits compact SVG without the XML declaration; the default
profile emits a fuller SVG document. The examples use both forms depending on what the output needs.

{{ tabs(base="snow-flake", dir="../showcase") }}
