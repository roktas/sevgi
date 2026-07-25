# Output Routing

Keep document construction and output policy separate. Choose the final operation from the artifact the caller needs:

| Artifact | Use |
| --- | --- |
| SVG String owned by surrounding Ruby code | `Render` |
| SVG on standard output | `Out` |
| SVG file | `Save` |
| PDF file | `PDF` |
| PNG file | `PNG` |
| Export an existing SVG String outside the document | `Sevgi::Sundries::Export.call` |

The `sevgi` command reads standard input when no file is given. Use `sevgi --as badge` when an implicit `Save`, `PDF`,
or `PNG` should derive `badge.svg`, `badge.pdf`, or `badge.png` instead of the default `output` basename. `NAME` is a
basename, not a path; explicit destinations in the source remain authoritative.

## PDF

For a document, use the convenience operation:

```ruby
canvas = SVG.Canvas width: 40, height: 40, unit: :px
drawing = SVG :minimal, canvas do
  circle cx: 20, cy: 20, r: 16, fill: "tomato"
end

drawing.PDF "badge.pdf"
```

For an application that owns the rendered SVG and output policy separately:

```ruby
canvas = SVG.Canvas width: 40, height: 40, unit: :px
svg = SVG(:minimal, canvas) { circle cx: 20, cy: 20, r: 16, fill: "tomato" }.Render
Sevgi::Sundries::Export.call(svg, "badge.pdf")
```

The output suffix selects PDF when `format:` is omitted. `width:` and `height:` are export dimensions; they do not
repair or replace the drawing's canvas, `viewBox`, or visible geometry. Fix those in the SVG document. Use `css:` only
for deliberate export-only styling, and use `dpi:` when the CSS-pixel-to-output conversion policy must differ.

SVG output has no native graphics dependency. PDF and PNG export lazily require Cairo, RSVG, and HexaPDF; report a
missing optional component rather than replacing the path with an unrequested external command or raster workaround.

## Verification

Inspect the produced artifact; a successful write does not prove correct rendering. For a parameterized or multi-page
family, start with a representative output and then check other variants affected by the same rule.

For PDF output, validate document structure with `qpdf` when available, render representative pages through Poppler or
an equivalent independent renderer, and inspect embedded fonts when fallback would change the result. Compare raster
output only as evidence; fix discrepancies in the SVG source, export policy, or environment that owns them.

Treat rendered SVGs, PDFs, PNGs, and visual snapshots as derived evidence, not implementation sources. Fix the
maintained Sevgi or editor-owned SVG/XML source and regenerate. Update expected artifacts only for an intentional output
change, then review the visible diff before accepting it.

Read [Sundries export](https://sevgi.roktas.dev/sundries/#export) for installation and examples, and
[`Sevgi::Sundries::Export`](https://www.rubydoc.info/gems/sevgi-sundries/Sevgi/Sundries/Export) for exact dimensions,
options, return paths, and errors.
