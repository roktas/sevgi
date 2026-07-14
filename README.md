[![test status](https://github.com/roktas/sevgi/workflows/Test/badge.svg)](https://github.com/roktas/sevgi/actions?query=workflow%3ATest)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ff0a9c3e65894040800b44867cd28198)](https://app.codacy.com/gh/roktas/sevgi/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# SEVGI

**SEVGI** builds SVG with a Ruby DSL[^1]. You can generate a drawing entirely in code or combine Ruby with files from a
vector editor. The DSL uses SVG element names directly and adds helpers for tasks such as tiling, hatching, and geometry.

Ruby input:

```ruby
SVG :minimal do
  g id: "group" do
    rect   id: "rectangular", width: 3, height: 5
    circle id: "circle", r: 1
  end
end
```

Simplified SVG output:

```svg
<svg>
  <g id="group">
    <rect id="rectangular" width="3" height="5"/>
    <circle id="circle" r="1"/>
  </g>
</svg>
```

## Usage

SEVGI works as a Ruby library, but `.sevgi` scripts are the quickest option when the drawing is the whole program. Add
the shebang, build the document, and call an output method on it.

Create `example.sevgi`:

```ruby
#!/usr/bin/env -S ruby -S sevgi

SVG do
  g id: "group" do
    rect   id: "rectangular", width: 3, height: 5
    circle id: "circle", r: 1
  end
end.Out
```

Make it executable and run it:

```bash
chmod +x example.sevgi
bundle exec ./example.sevgi
```

The script writes:

```svg
<?xml version="1.0" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg">
  <g id="group">
    <rect id="rectangular" width="3" height="5"/>
    <circle id="circle" r="1"/>
  </g>
</svg>
```

See [Showcase](showcase/srv) for examples and output.

## Requirements

Sevgi requires Ruby 3.4.0 or newer. CI verifies the exact Ruby 3.4.0 floor and the current development Ruby version
recorded in `.ruby-version`.

SVG-only usage does not require native export gems. PDF/PNG export uses `sevgi-sundries` lazily and requires the
optional Ruby gems `cairo`, `rsvg2`, and `hexapdf`.

On Debian/Ubuntu, install the native libraries first:

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

## Project structure

The repository contains eight components. `graphics` is the core; the others add conversion, shared functions,
geometry, validation, helper objects, examples, and the top-level API. Each component is a Ruby gem. Most gem names use
the `sevgi-` prefix, while the top-level gem is simply `sevgi`. Components define matching namespaces under `Sevgi`.

### `derender` - `Sevgi::Derender`

Derender converts SVG or XML into Sevgi source. It is useful for artwork that begins in a vector editor, especially a
shape with dense Bezier curves that would be tedious to reproduce by hand in Ruby.

`Include` uses derender internally to evaluate SVG fragments inside the current document.

```ruby
Tile "tile", nx: 2, dx: 1, ny: 3, dy: 4 do
  Include "fruits", "apple"
end
```

### `function` - `Sevgi::Function`

Function contains helpers shared by several components, such as `F.round`. `F` and `Sevgi::Function` refer to the same
public object in library and script code. Helpers that belong to one component stay with that component; larger shared
objects belong in `sundries`.

### `geometry` - `Sevgi::Geometry`

Geometry provides the calculations that cannot be left to the SVG renderer. It stays small on purpose and covers only
the operations Sevgi drawings need.

### `graphics` - `Sevgi::Graphics`

Graphics implements the DSL and document tree. In the opening example, the `SVG` root has one child, the `g` group.
That group contains the `rect` and `circle` elements.

### `showcase`

Showcase contains executable examples under `srv` and the documentation site under `doc`.

### `standard` - `Sevgi::Standard`

Standard checks DSL output against the SVG element and attribute rules. For example:

```ruby
rect id: "rectangular", width: 3, height: 5 do
  circle id: "circle", r: 1, x: 2
end
```

The `standard` component catches two errors in this example:

- `rect` is not a container element in the SVG standard, but a `circle` element was added as its child with a `do..end`
  block.
- The `circle` element was given an `x` attribute, which is not defined for it in the standard.

### `sundries` - `Sevgi::Sundries`

Sundries contains shared objects such as `Grid` and optional output tools such as `Export`.

### `toplevel` - `Sevgi::Toplevel`

Toplevel provides the `sevgi` gem, the script runner, and the full `include Sevgi` or `extend Sevgi` API. Classes and
modules receive constants such as `F`, `Geometry`, `Origin`, and `Export`. Extending an ordinary object adds DSL methods
without writing constants to `Object`.

## Release

Maintainers can publish locally with `rake release` from a clean `main` checkout. The task builds every component,
checks remote versions and checksums before the first push, then publishes in dependency order. If preflight fails, it
publishes nothing.

GitHub Actions `Ship` is the preferred route when using trusted RubyGems credentials. Do not mix local and workflow
publishing for the same version.

## Roadmap

> [!WARNING]
>
> The project is currently in the alpha stage, so many things might not work and many things can change.

Beta stage

- [ ] Complete user documentation.

Final stage

- [ ] Complete Geometry library.

[^1]:
    Inspired by [Victor](https://github.com/DannyBen/victor), which may suit projects that need a smaller API. Several
    Sevgi examples are adapted from Victor's examples, with thanks to its author.
