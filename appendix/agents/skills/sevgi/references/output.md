# Output Routing

Keep document construction and output policy separate. Choose the final operation from the artifact the caller needs:

| Artifact                                           | Use                            |
| -------------------------------------------------- | ------------------------------ |
| SVG String owned by surrounding Ruby code          | `Render`                       |
| SVG on standard output                             | `Out`                          |
| SVG file                                           | `Save`                         |
| PDF file                                           | `PDF`                          |
| PNG file                                           | `PNG`                          |
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

SVG output has no native graphics dependency. Ordinary PDF and PNG export lazily require Cairo, RSVG, and HexaPDF.
Report a missing optional component rather than substituting an unrequested command or raster workaround.

### Editable styles

Use the document's `Style` operation when the caller needs editable PDF paint controls:

```ruby
drawing.Style do
  Target "ink", selectors: ["#outline"]
  Param "display", targets: ["ink"], property: "display",
    schema: {type: "string", enum: %w[inline none]}
  Param "opacity", targets: ["ink"], property: "stroke-opacity",
    schema: {type: "number", minimum: 0, maximum: 1}
end
drawing.PDF "prepared.pdf", fallback: false
```

The SVG must contain the selected group or direct `use` placement. Each target needs a `display` parameter.
Keep JSON Schema names such as `minimum` and `maximum`. `Group` orders controls; `Profiles` declares named overrides.
`Style` changes export metadata, not SVG appearance. Lowercase `style` remains the SVG CSS element.

`drawing.Style` returns a deeply frozen Hash with JSON String keys, or nil when no declaration is attached.
Pass this Hash as `style:` to `Sevgi::Sundries::Export.call` when the application owns the SVG separately.
For explicit required production, use `Sevgi::Sundries::Mainz.produce(svg, output, declaration: drawing.Style)`.

Styled PDF export uses the native `mainz` executable on `PATH`. It does not load the Mainz extension or ordinary export
gems. By default, missing Mainz or failed preparation warns and falls back to ordinary PDF export.
Use `fallback: false` when the prepared contract is required; preparation failures then raise
`Sevgi::Sundries::Mainz::Error`. Unstyled exports remain ordinary in either mode.
Invalid arguments, filesystem failures, and interrupts propagate in both modes. Parallel exports use separate staging.
Mainz owns selector admission, supported paint properties, and PDF baselines. Publication policy stays with the caller.

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
