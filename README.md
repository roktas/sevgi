[![test status](https://github.com/roktas/sevgi/workflows/Test/badge.svg)](https://github.com/roktas/sevgi/actions?query=workflow%3ATest)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ff0a9c3e65894040800b44867cd28198)](https://app.codacy.com/gh/roktas/sevgi/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# SEVGI

**SEVGI** is a toolkit for creating SVG content programmatically with a Ruby-based DSL[^1]. With this toolkit, you can
create pixel-perfect graphics either without a vector graphics editor or together with one. Thanks to a mixin-based
design, you can easily add custom features and use a rich set of methods, especially for tiling, hatching and various
geometric operations. In brief:

- Input:

  ```ruby
  SVG :minimal do
    g id: "group" do
      rect   id: "rectangular", width: 3, height: 5
      circle id: "circle", r: 1
    end
  end
  ```

- Output (roughly simplified):

  ```svg
  <svg>
    <g id="group">
      <rect id="rectangular" width="3" height="5"/>
      <circle id="circle" r="1"/>
    </g>
  </svg>
  ```

## Usage

**SEVGI** can be used as a regular Ruby library, but the recommended usage is the "script" mode. In this mode, add the
correct shebang and call an I/O method on the SVG object to produce output. Use `.sevgi` as the preferred script file
extension.

- Create the script (`example.sevgi`)

  ```ruby
  #!/usr/bin/env -S ruby -S sevgi

  SVG do
    g id: "group" do
      rect   id: "rectangular", width: 3, height: 5
      circle id: "circle", r: 1
    end
  end.Out
  ```

- Run the script

  ```bash
  chmod +x example.sevgi
  bundle exec ./example.sevgi
  ```

- Output

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

Sevgi requires Ruby 3.4.0 or newer. CI verifies the minimum Ruby 3.4 line and the current development Ruby version
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

## Project Structure

The project consists of 8 components, with the core `graphics` component at the center. In alphabetical order, the
components are: `derender`, `function`, `geometry`, `graphics`, `showcase`, `standard`, `sundries`, and `toplevel`.
Each component is packaged as a Ruby gem. Most component gems use the `sevgi-` prefix (for example, `sevgi-graphics`);
the top-level component is the `sevgi` gem. Except for `showcase`, each component defines a separate namespace under
`Sevgi` (for example, `Sevgi::Graphics`).

### `derender` - `Sevgi::Derender`

This component converts SVG content (XML code) into the Sevgi DSL (Ruby code). It is especially useful for converting
graphics created with a vector graphics editor that would be very hard to create directly with the DSL, such as shapes
with dense Bezier curves. This makes it possible to combine Sevgi's programmatic graphics workflow with the manual
workflow of vector drawing tools.

Example scenario:

`Include` uses derender internally to evaluate SVG fragments inside the current document.

```ruby
Tile "tile", nx: 2, dx: 1, ny: 3, dy: 4 do
  Include "fruits", "apple"
end
```

### `function` - `Sevgi::Function`

General helper methods used across all components (for example, `F.round`). `F` is the same public object as
`Sevgi::Function` in library, included, and script modes, so all function helpers are available through the same alias.
This component contains general-purpose code that is used at least a few times across multiple components. Helper
methods or objects that are specific to one component live in that component. For larger helper **objects** that are not
specific to any component, prefer the `sundries` component.

### `geometry` - `Sevgi::Geometry`

A geometry calculation library usable from the Sevgi DSL. Because the guiding principle is "avoid doing calculations;
use the SVG renderer", this library contains only simple geometric operations needed in unavoidable cases.

### `graphics` - `Sevgi::Graphics`

The main component that implements the Sevgi DSL. A graphic element created through the DSL is essentially a tree
structure. In the example at the beginning of this document, the root tree created with `SVG` has a single child, the
`g` group element. The `rect` and `circle` elements are the two children of that group element.

### `showcase`

This component contains Sevgi examples under `srv` and the website under `doc`.

### `standard` - `Sevgi::Standard`

This component checks the elements and attributes being produced with the Sevgi DSL against SVG standards and prevents
invalid usage. For example:

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

Helper objects (for example, `Grid`) and tools (for example, `Export`) that are not specific to a single component.
These helper objects and tools do not need to be actively used in the current code; it is enough that they are known to
be useful in various scenarios.

### `toplevel` - `Sevgi::Toplevel`

This component provides the full `include Sevgi` / `extend Sevgi` DSL. Classes and modules receive promoted constants
such as `F`, `Geometry`, `Origin`, and `Export`; extending an ordinary object installs DSL methods without mutating
global `Object` constants.

## Roadmap

> [!WARNING]
>
> The project is currently in the alpha stage, so many things might not work and many things can change.

Beta stage

- [ ] Complete user documentation.

Final stage

- [ ] Complete Geometry library.

[^1]:
    Inspired by [Victor](https://github.com/DannyBen/victor), which might be a better choice for those seeking something
    simpler. Please note that a fair amount of the examples used for demonstration purposes come from this project
    (thanks to the author).
