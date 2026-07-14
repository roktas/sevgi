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

The default profile includes a fuller preamble and namespaces. `:minimal` is useful for compact fragments and tests;
`:inkscape` adds editor namespaces and editor-oriented DSL.

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
