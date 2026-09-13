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

The `sevgi` command reads standard input when no file is given. Use `sevgi --as badge` to make an implicit `Save`, `PDF`,
or `PNG` derive `badge.svg`, `badge.pdf`, or `badge.png` instead of the default `output` basename. `NAME` is a
basename, not a path. Explicit destinations in the source remain authoritative.

## PDF

For a document, use the convenience operation:

```ruby
canvas = SVG.Canvas width: 40, height: 40, unit: :px
drawing = SVG canvas do
  circle cx: 20, cy: 20, r: 16, fill: "tomato"
end

drawing.PDF "badge.pdf"
```

For an application that owns the rendered SVG and output policy separately:

```ruby
canvas = SVG.Canvas width: 40, height: 40, unit: :px
svg = SVG canvas do
  circle cx: 20, cy: 20, r: 16, fill: "tomato"
end.Render
Sevgi::Sundries::Export.call(svg, "badge.pdf")
```

The output suffix selects PDF when `format:` is omitted. `width:` and `height:` are export dimensions. They do not
repair or replace the drawing's canvas, `viewBox`, or visible geometry. Fix those in the SVG document. Use `css:` only
for deliberate export-only styling, and use `dpi:` when the CSS-pixel-to-output conversion policy must differ.

Export CSS is a last-minute adjustment after document validation. It still obeys the CSS cascade.
Insertion requires well-formed SVG ending in an unprefixed `</svg>` plus optional XML whitespace.
Self-closing or prefixed roots and comments after the root are unsupported with `css:`. Without CSS, this restriction
does not apply. Sevgi escapes CSS as XML text but does not validate the stylesheet. Native `Export.call` runs its source
callback after insertion and before conversion. Inspect the final output for changed visibility, size, and clipping.

SVG output has no native graphics dependency. PDF and PNG export lazily require Cairo, RSVG, and HexaPDF. Report a
missing optional component rather than replacing the path with an unrequested external command or raster workaround.

## Verification

Inspect the produced artifact. A successful write does not prove correct rendering. For a parameterized or multi-page
family, start with a representative output and then check other variants affected by the same rule.

For PDF output, validate document structure with `qpdf` when available, render representative pages through Poppler or
an equivalent independent renderer. Inspect embedded fonts when fallback changes the result. Compare raster output
only as evidence. Fix discrepancies in the SVG source, export policy, or environment that owns them.

Treat rendered SVGs, PDFs, PNGs, and visual snapshots as derived evidence, not implementation sources. Fix the
maintained Sevgi or editor-owned SVG/XML source and regenerate. Update expected artifacts only for an intentional output
change, then review the visible diff before accepting it.

Read [Output](https://sevgi.roktas.dev/output/) for SVG, PDF, and PNG workflows, and
[`Sevgi::Sundries::Export`](https://www.rubydoc.info/gems/sevgi-sundries/Sevgi/Sundries/Export) for exact dimensions,
options, return paths, and errors.
