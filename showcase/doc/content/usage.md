+++
title = "One DSL, Two Hosts"
weight = 2
[extra]
group = "Start"
+++

Sevgi does not split its drawing vocabulary into a script API and a library API. Both hosts build the same document
objects and use the same words. A script promotes capitalized operations into its managed scope; library code calls
those operations through the `SVG` facade.

## Script mode

A script gets the top-level DSL automatically and can be run directly:

```ruby
#!/usr/bin/env -S ruby -S sevgi

SVG :minimal do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save
```

Scripts work well for generated assets, plotter input, and build jobs. [Script Mode](@/script-mode.md) covers the
runner and its top-level API.

## Library mode

`require "sevgi"` provides the same `SVG(...)` document builder and the `SVG` facade. Moving the drawing block into an
application does not change its spelling:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 24, height: 24, unit: :px

drawing = SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end

File.write("badge.svg", drawing.Render)
```

The equivalent script can write `Canvas(...)` without the `SVG.` receiver. The resulting object is still an
`SVG::Canvas`. Output is an ownership choice: scripts commonly call `Save` or `Out`, while applications commonly keep
the document and call `Render` when their storage or response layer needs a String.

## Where names live

| Role | `.sevgi` script | Ruby library |
| --- | --- | --- |
| Build a document | `SVG(...)` | `SVG(...)` |
| SVG operation | `Canvas(...)`, `Paper(...)`, `Derender(...)` | `SVG.Canvas(...)`, `SVG.Paper(...)`, `SVG.Derender(...)` |
| SVG type or namespace | `SVG::Canvas`, `SVG::Module` | `SVG::Canvas`, `SVG::Module` |
| Execute trusted Sevgi source | managed by the runner | `Sevgi.execute`, `Sevgi.execute_file` |

A dot followed by a capitalized word denotes a facade operation. Double colons denote a Ruby constant, type, or
namespace. `SVG.Canvas(...)` therefore creates a value whose type is `SVG::Canvas`. The document builder remains the
global `SVG(...)` method; there is no `SVG.SVG(...)` spelling.

The full `Sevgi` namespace also owns the promoted operations used by inclusion and script execution, so forms such as
`Sevgi.Canvas(...)` exist. Prefer the `SVG` facade for ordinary library work in the SVG domain. Process-level operations
such as `Sevgi.execute` deliberately stay on `Sevgi`.

Library mode fits code that returns SVG in an HTTP response, compares it in a test, or writes it through an existing
storage layer. [Library Mode](@/library-mode.md) explains the namespace choices.

## Do examples need both forms?

Usually no. Repeating every example obscures the idea being taught. This site labels context in the DSL catalog and
uses paired examples only where the forms behave differently, such as document construction, loading, and output.
Inside an `SVG` block, both hosts use the same drawing words. Qualification only changes how Ruby finds operations
outside that block.
