# Sevgi Graphics

Sevgi Graphics implements the SVG DSL, document profiles, and rendering.

## Install

```sh
gem install sevgi-graphics
```

## Require

```ruby
require "sevgi/graphics"
```

## Example

```ruby
doc = Sevgi::Graphics.SVG(:minimal) { rect width: 3, height: 5 }
puts doc.Render
```

This focused gem exposes `Sevgi::Graphics.SVG` and lowercase component constructors. Install the umbrella `sevgi` gem
when you need the global `SVG` facade or the `.sevgi` script runner.

## PDF page metadata and controls

`Imprint` attaches an immutable producer declaration to an SVG document.
It does not change the SVG or load a PDF backend.
The lowercase `style` method still creates an SVG CSS element.

```ruby
doc = Sevgi::Graphics.SVG width: 20, height: 20 do
  g id: "outline" do
    rect width: 10, height: 10, fill: "none", stroke: "black"
  end
  Imprint do
    Page name: "ITAL-ARCH-60A4-WXGF", tags: ["practice"]
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

doc.PDF "drawing.pdf"
doc.PDF "prepared.pdf", fallback: false
```

`PDF` uses Mainz automatically when the document has an Imprint declaration or a preview is supplied.
If Mainz is unavailable or preparation fails, the default mode warns and exports an ordinary PDF.
`fallback: false` raises `Sevgi::Sundries::Imprint::Error` instead.
A PDF without a declaration or preview uses ordinary export without a Mainz warning.
PNG and SVG output retain their ordinary behavior.

`Target` selects whole SVG groups or direct `use` placements with `#id` or `#id > use.class` selectors.
Its optional `fill: true` allows eligible closed paths to acquire a fill.
`Param` binds one supported paint property to targets and supplies its value schema.
`Group` orders parameter references. `Profiles` records named sets of overrides.
`Page` supplies optional `name` and `tags` for the physical PDF page. Names need not be unique.
`Page` also works alone in an Imprint block. That metadata does not create editable paint controls.
Every target requires at least one parameter binding.
`Param` accepts an optional `value:` to assign an override after Mainz captures original paint.
For an authored hidden target, `Target` accepts `display: "none"`.
Mainz owns selector resolution, supported properties, binding admission, and PDF baselines.
The [declaration contract](https://github.com/roktas/mainz/blob/main/lib/doc/SPEC.md#71-svg-declarations) defines those fields.

`doc.Imprint` returns the declaration as deeply frozen JSON data with String keys.
`doc.Imprint declaration_hash` accepts the same fields without a builder block.
Its optional `page` Hash has the same fields as the `Page` operation. Pass PNG thumbnail bytes separately with
`doc.PDF "drawing.pdf", preview: png_bytes, fallback: false`; image paths and bytes do not enter the Imprint declaration.
Applications supply their own parameter names, schemas, profiles, and publication requirements.
Separate documents have separate declarations. Document copies safely share an immutable declaration.
Invalid Ruby declarations raise `Sevgi::ArgumentError` before export.

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs only Ruby and its Ruby dependencies.

## Links

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-graphics>
- Source: <https://github.com/roktas/sevgi/tree/main/graphics>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
