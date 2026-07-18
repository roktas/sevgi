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

## Validation lifecycle

`Render`, `Save`, and `Out` prepare a document before writing it. Call `PreRender(validate: true, lint: true)` to run
that phase yourself, or use `Validate()` and `Lint()` for an earlier check. For non-SVG XML, choose a suitable document
profile or render directly instead of running the standard SVG checks.

For the standard vocabulary, use the
[MDN SVG element reference](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element). For Sevgi operations,
use the [DSL Catalog](@/dsl.md).
