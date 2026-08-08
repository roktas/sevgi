+++
title = "Output"
weight = 15
[extra]
group = "Guides"
+++

This page explains how a finished document reaches a Ruby application, a file, or a shell pipeline. Sevgi can return
SVG text, write SVG directly, or convert the rendered document to PDF or PNG. The drawing's canvas and visible geometry
should already be correct before output begins.

## SVG {{ "{#svg}" }}

Choose the operation by where the result should go:

| Need | Use |
| --- | --- |
| Return an SVG String to Ruby | `Render` |
| Write SVG beside the active `.sevgi` source | `Save` |
| Write SVG to a specific path | `Write` or `Save` with a path |
| Print SVG to standard output | `Out` |

Library code commonly keeps the document and passes `Render` to its own storage or response layer:

```ruby
require "sevgi"

drawing = SVG(:minimal) { circle cx: 12, cy: 12, r: 10 }
File.write "badge.svg", drawing.Render
```

Executable drawings can let the runner derive a path from the source name:

```ruby
#!/usr/bin/env -S ruby -S sevgi

SVG :minimal do
  circle cx: 12, cy: 12, r: 10
end.Save
```

For `badge.sevgi`, the implicit destination is `badge.svg` in the same directory. `Write "build/badge.svg"` and
`Save "build/badge.svg"` use the given path instead. `Out` writes the same rendered SVG to standard output.

## Input names {{ "{#names}" }}

The `sevgi` command reads a file operand, `-`, or standard input when no file is given. Standard input has the logical
name `output.sevgi`, so an implicit `Save`, `PDF`, or `PNG` writes `output.svg`, `output.pdf`, or `output.png`.

Use `--as NAME` when a pipeline has a more useful identity. `NAME` is a basename, not a path:

```sh
sevgi --as badge < drawing.sevgi
```

This evaluates the input as `badge.sevgi`, making an implicit `Save` write `badge.svg`. The option also works with a
file operand and keeps the file's directory, so relative `Load` calls still resolve beside the source:

```sh
sevgi --as proof drawings/card.sevgi
```

Here an implicit `Save` writes `drawings/proof.svg`. Explicit destinations and an explicit `default:` always take
precedence over the logical input name. Applications using `Sevgi.execute_file` can set the same logical basename with
its `as:` option; see [Usage](@/usage.md#execute).

## PDF and PNG {{ "{#export}" }}

SVG output needs no native graphics libraries. PDF and PNG conversion is optional and available through document
operations:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 40, height: 40, unit: :px
drawing = SVG :minimal, canvas do
  circle cx: 20, cy: 20, r: 16, fill: "tomato"
end

drawing.PNG "badge.png", dpi: 144
drawing.PDF "badge.pdf"
```

Applications that keep output policy outside the document can call the component directly. The file suffix selects
the format when `format:` is omitted, and the return value is the expanded output path:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 40, height: 40, unit: :px
drawing = SVG(:minimal, canvas) { circle cx: 20, cy: 20, r: 16, fill: "tomato" }
Sevgi::Sundries::Export.call drawing.Render, "badge.png", width: 320
```

Export `width` and `height` control output dimensions. They do not replace the SVG canvas, repair its `viewBox`, or
change the drawing's visible geometry. Define those relationships in the document before export. Use `css:` only for
deliberate export-only styling, and use `dpi:` when CSS pixels need a different conversion policy.

PDF and PNG output uses Cairo, librsvg, and HexaPDF. If one is missing, Sevgi raises a component error. Ordinary SVG
rendering continues to work without these optional dependencies.
