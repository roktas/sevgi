+++
title = "Output"
weight = 15
[extra]
group = "Guides"
+++

A finished document can return SVG text, write SVG to a file or shell pipeline, or convert to PDF or PNG. Set the
canvas and visible geometry before output begins.

## SVG {{ "{#svg}" }}

Choose the operation by its destination:

| Need | Use |
| --- | --- |
| Return an SVG String to Ruby | `Render` |
| Write SVG beside the active `.sevgi` source | `Save` |
| Write SVG to a specific path | `Write` or `Save` with a path |
| Print SVG to standard output | `Out` |

Library code commonly keeps the document and passes `Render` to its own storage or response layer:

```ruby
require "sevgi"

drawing = SVG(width: 24, height: 24) { circle cx: 12, cy: 12, r: 10 }
File.write "badge.svg", drawing.Render
```

Executable drawings can let the runner derive a path from the source name:

```ruby
#!/usr/bin/env -S ruby -S sevgi

SVG width: 24, height: 24 do
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
its `as:` option. See [Usage](@/usage.md#execute).

## PDF and PNG {{ "{#export}" }}

SVG output needs no native graphics libraries. PDF and PNG conversion is optional and available through document
operations:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 40, height: 40, unit: :px
drawing = SVG canvas do
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
drawing = SVG(canvas) { circle cx: 20, cy: 20, r: 16, fill: "tomato" }
Sevgi::Sundries::Export.call drawing.Render, "badge.png", width: 320
```

Export `width` and `height` control output dimensions. They do not replace the SVG canvas, repair its `viewBox`, or
change the drawing's visible geometry. Define those relationships in the document before export. Use `css:` only for
deliberate export-only styling, and use `dpi:` when CSS pixels need a different conversion policy.

Ordinary PDF and PNG output uses Cairo, librsvg, and HexaPDF. If one is missing, Sevgi raises a component error. Ordinary SVG
rendering continues to work without these optional dependencies.

### Editable PDF styles {{ "{#editable-pdf}" }}

`Style` attaches a producer declaration to your document without changing its SVG.
A prepared PDF contains editable paint controls and their original values.
Mainz resolves the declaration and embeds those controls during PDF production.

```ruby
require "sevgi"

drawing = SVG width: 20, height: 20 do
  g id: "outline" do
    rect width: 10, height: 10, fill: "none", stroke: "black"
  end
  Style do
    Target "ink", selectors: ["#outline"]
    Param "display", targets: ["ink"], property: "display",
      schema: {type: "string", enum: %w[inline none]}
    Param "opacity", targets: ["ink"], property: "stroke-opacity",
      schema: {type: "number", minimum: 0, maximum: 1}
    Group "Ink", parameters: ["opacity"]
    Profiles "print", name: "Printer", parameters: ["opacity"], profiles: [
      {id: "original", name: "Original", overrides: {}},
      {id: "light", name: "Light", overrides: {opacity: 0.4}}
    ]
  end
end

drawing.PDF "drawing.pdf"
```

`PDF` attempts Mainz preparation when the document has a Style declaration.
If Mainz is unavailable or preparation fails, the default mode warns and exports an ordinary PDF.
`drawing.PDF "prepared.pdf", fallback: false` raises `Sevgi::Sundries::Mainz::Error` instead.
An unstyled PDF uses ordinary export without a Mainz warning.
Invalid arguments, filesystem failures, and interrupts remain errors in both modes.

`Target` selects SVG groups or direct `use` placements with `#id` or `#id > use.class` selectors.
Each target requires a `display` parameter. `Param` binds one supported paint property and supplies its value schema.
Its optional `value:` assigns an override after Mainz captures the original paint.
`Group` orders controls. `Profiles` supplies named sets of overrides, with an empty first profile for the original values.
The lowercase `style` method still creates an SVG CSS element.

`drawing.Style` returns a deeply frozen Hash with JSON String keys, or nil when no declaration is attached.
`drawing.Style declaration_hash` accepts a declaration without a builder block.
Applications can pass `drawing.Style` to `Sevgi::Sundries::Export.call` with `style:`.
`Sevgi::Sundries::Mainz.produce` accepts SVG text, an output path, and `declaration:` for explicit required production.
Declarations contain deeply frozen JSON data and remain local to each document.
Mainz owns selector resolution, supported properties, binding admission, and PDF baselines.

This feature requires the native `mainz` executable on `PATH`.
Prepared export does not load the Mainz Ruby extension or the ordinary export gems.
Parallel calls use separate temporary directories.
The [Mainz declaration contract](https://github.com/roktas/mainz/blob/main/lib/mainz/README.md) defines the producer fields and limits.

### Last-minute export CSS

The `css:` option adds a stylesheet to the finished SVG just before conversion. For example, it can hide crop guides
in a PDF without changing the saved SVG:

```ruby
require "sevgi"

drawing = SVG width: 40, height: 40 do
  rect width: 40, height: 40, fill: "gold"
  circle class: "guide", cx: 20, cy: 20, r: 16, fill: "none", stroke: "black"
end
drawing.PDF "print.pdf", css: ".guide { display: none; }"
```

This is an export-only adjustment after Sevgi's document checks. It does not replace document CSS or bypass the CSS
cascade. Inline styles and `!important` declarations can still take precedence.

CSS insertion accepts well-formed SVG whose final root tag is exactly `</svg>`, followed only by XML whitespace.
Self-closing roots, prefixed root tags, and comments after the root are unsupported with `css:`.
Sevgi raises `Sevgi::Sundries::Export::ExportError` before it changes the output file for these endings.
Without `css:`, this insertion restriction does not apply.

Sevgi escapes the CSS as XML text but does not parse or validate the stylesheet.
`Export.call` runs its optional source callback once after CSS insertion and before ordinary or prepared conversion.
Inspect the final PDF or PNG: export CSS can change size, visibility, and clipping after document validation.

## Replace PDF placeholders {{ "{#pdf-placeholders}" }}

`Export.stamp` replaces exact placeholder text in a PDF. The placeholder must be a literal string inside a white text
object that matches Sevgi's stamp pattern. For example, use
`Export.stamp("certificate.pdf", "certificate-jane-doe.pdf", placeholder: "RECIPIENT", stamp: "Jane Doe")`.
A successful replacement writes the destination file and returns `true`.

The method returns `false` and writes no output when it finds no match. Use `Export.stamp!` to replace the input file
only after a successful, nonempty rewrite.
