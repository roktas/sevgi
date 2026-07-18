+++
title = "SVG Essentials"
weight = 10
[extra]
group = "Core"
+++

An SVG document is an element tree plus a document profile. Lowercase calls add SVG elements to the tree. Sevgi's
capitalized words move, copy, group, or otherwise operate on those elements. The standard component checks known SVG
names and their allowed attributes, content, and parents.

## Construct a document

```ruby
drawing = SVG :minimal, width: 32, height: 20 do
  g id: "badge" do
    rect width: 32, height: 20, rx: 4, fill: "gold"
    text "S", x: 16, y: 14, "text-anchor": "middle"
  end
end

drawing.Render
```

## Document profiles {#document-profiles}

A profile controls document metadata and extra DSL capabilities, not canvas size or checking policy. All four profiles
use the same validation and lint lifecycle.

| Profile | Preamble | Root metadata | Additional DSL |
| --- | --- | --- | --- |
| `:minimal` | none | none | common document DSL |
| `:default` | XML declaration | SVG namespace | common document DSL |
| `:html` | none | SVG namespace | common document DSL |
| `:inkscape` | XML declaration | SVG and editor namespaces; crisp edges | `Draw`, `Hatch`, and editor/RDF helpers |

Use `:minimal` for compact output or as the superclass of a custom profile, `:default` for a standalone SVG file,
`:html` for SVG embedded in HTML, and `:inkscape` when editor metadata or its additional helpers belong to the drawing.
The Inkscape root adds Sevgi, Inkscape, and Sodipodi namespaces plus `shape-rendering="crispEdges"`. The presence of
`Draw` and `Hatch` on `:inkscape` is a convenience default, not an Inkscape format requirement.

`Sevgi::Graphics::Document::Base` is the public common extension layer, not a selectable profile. Advanced consumers
can target it with `Mixin` to change every descendant profile process-wide. Prefer a subclass of
`Sevgi::Graphics::Document::Minimal` when an extension should remain scoped.

For example, `Draw` and `Hatch` can be added to a private Minimal-derived profile without adopting Inkscape metadata:

```ruby
profile = Class.new(Sevgi::Graphics::Document::Minimal)
Sevgi::Graphics::Mixtures.mixin(:Hatch, profile)
region = Sevgi::Geometry::Rect[24, 12]

Sevgi::Graphics.SVG(profile) do
  Draw region.lines, stroke: "silver"
  Hatch region, angle: 30, step: 3, stroke: "black"
end.Render
```

## Element dispatch {#elements}

The DSL recognizes SVG element names dynamically, so it does not need a Ruby method for every element in each SVG
release. Sevgi validates the resulting standard SVG before checked output. Names are case-sensitive: `linearGradient`
is an SVG element, while `LinearGradient` would be a different Ruby call.

Use `Element` when producing foreign XML or when a qualified name cannot be expressed as a bare Ruby call:

```ruby
SVG :minimal do
  Element "catalog:item", "featured", "catalog:rank": 1
end.Render
```

## Content safety {#content-safety}

Ordinary String arguments are XML text-encoded automatically. Use a `Content` constructor only when content needs a
different serialization channel.

| Input | Use | Safety contract |
| --- | --- | --- |
| Ordinary text argument | `text "A & B"` | encoded automatically |
| Explicit reusable text content | `Content.encoded` | XML text-encoded |
| Literal text body in a CDATA section | `Content.cdata` | CDATA terminators split safely |
| CSS rules expressed as a Hash | `Content.css` | rendered as CSS inside CDATA |
| Already serialized trusted markup | `Content.verbatim` | deliberately unescaped; caller owns well-formedness and escaping |

```ruby
drawing = SVG :minimal do
  text "A & B"
  text Sevgi::Graphics::Content.encoded("A & B")
  style Sevgi::Graphics::Content.cdata(".note { fill: red; }")
  style Sevgi::Graphics::Content.css(".note" => {fill: "red"})
  g Sevgi::Graphics::Content.verbatim("<title>trusted markup</title>")
end

drawing.Render
```

Advanced consumers may subclass `Sevgi::Graphics::Content` and implement `render(output, depth)`. The rendering engine
ignores the method's return value. A custom implementation must escape any data it inserts into markup; use
`Content.encoded(...).to_s` rather than interpolating caller text directly.

## Validation lifecycle

`Render`, `Save`, and `Out` prepare a document before writing it. Call `PreRender(validate: true, lint: true)` to run
that phase yourself, or use `Validate()` and `Lint()` for an earlier check. For non-SVG XML, choose a suitable document
profile or render directly instead of running the standard SVG checks.

For the standard vocabulary, use the
[MDN SVG element reference](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element). For Sevgi operations,
use the [DSL Catalog](@/dsl.md).
