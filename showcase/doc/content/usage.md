+++
title = "One DSL, Two Hosts"
weight = 2
[extra]
group = "Start"
+++

A Sevgi drawing can be a complete executable program or a value produced inside another Ruby application:

- In **script mode**, a `.sevgi` file is the program. The runner supplies Sevgi's entry points and the script usually
  writes or prints its result.
- In **library mode**, an application requires Sevgi, builds a document, and decides when and where to use the rendered
  SVG string.

The `SVG` drawing block is identical in both modes. Operations around that block are bare words in a script and
capitalized methods on the `SVG` facade in library code.

## Script mode

A script gets the top-level DSL automatically and can be run directly:

```ruby
#!/usr/bin/env -S ruby -S sevgi

canvas = Canvas width: 24, height: 24, unit: :px

SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save "badge.svg"
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

File.write "badge.svg", drawing.Render
```

The drawing geometry is unchanged. The script calls `Canvas(...)` because the runner promotes that operation into its
scope; the application calls the same operation as `SVG.Canvas(...)`. Both return an `SVG::Canvas`. The script hands
the document to `Save`, while the application keeps the document and writes its `Render` result through ordinary Ruby.

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

## Choose a mode

Use script mode when the drawing itself is the program, such as a generated asset, plotting job, or build step. Use
library mode when an application owns the lifecycle, such as an HTTP response, test fixture, database value, or larger
rendering pipeline. Library code that must run a complete trusted `.sevgi` program can use `Sevgi.execute` or
`Sevgi.execute_file` instead of rebuilding the runner.
