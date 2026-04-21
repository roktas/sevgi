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

## Project Structure

The project consists of 8 components, with the core `graphics` component at the center. In alphabetical order, the
components are: `derender`, `function`, `geometry`, `graphics`, `showcase`, `standard`, `sundries`, and `toplevel`. Each
component is also a Ruby gem with the `sevgi-` prefix (for example, `sevgi-graphics`) and, except for `showcase`,
defines a separate namespace under `Sevgi` (for example, `Sevgi::Graphics`).

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

General helper methods used across all components (for example, `F.round`). For convenience, all methods can be called
through `F` instead of `Function`. This component contains general-purpose code that is used at least a few times across
multiple components. Helper methods or objects that are specific to one component live in that component. For larger
helper **objects** that are not specific to any component, prefer the `sundries` component.

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

This component injects selected library symbols (for example, `SVG`) into the top level, especially for use in "script"
mode.

## Roadmap

> [!WARNING]
>
> The project is currently in the alpha stage, so many things might not work and many things can change.

Alpha stage

- [ ] Stabilize API.
- [ ] Complete unit tests for all critical code paths.
- [ ] Populate examples while adding integration tests.
- [ ] Write entry-level user documentation.

Beta stage

- [ ] Complete user documentation.
- [ ] Start documenting API.

Final stage

- [ ] Complete Geometry library.

## AI Usage Policy

> [!NOTE]
>
> Project code before version 0.42.0 was written manually, without AI assistance. Starting with version 0.42.0, AI
> assistance is used actively, especially for tests and documentation.

AI is now an active part of the development workflow. However, every AI-generated code change is reviewed line by line
by a human maintainer before it is added to the codebase.

[^1]:
    Inspired by [Victor](https://github.com/DannyBen/victor), which might be a better choice for those seeking something
    simpler. Please note that a fair amount of the examples used for demonstration purposes come from this project
    (thanks to the author).
