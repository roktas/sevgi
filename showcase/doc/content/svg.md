+++
title = "SVG Essentials"
weight = 10
[extra]
group = "Core"
+++

An SVG document is an element tree with a document profile. Lowercase element calls build the tree; capitalized Sevgi
words operate on it. The standard component checks known SVG names, attributes, content, and parent/child relations.

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

Known SVG element names are accepted dynamically, so the DSL does not need one Ruby method per SVG release. Sevgi then
validates the resulting standard SVG before checked output. Names are case-sensitive: `linearGradient` follows SVG,
while `LinearGradient` would be a different Ruby call.

Use `Element` when producing foreign XML or when a qualified name cannot be expressed as a bare Ruby call:

```ruby
SVG(:minimal) do
  Element "catalog:item", "featured", "catalog:rank": 1
end.Render
```

## Validation lifecycle

`Render`, `Save`, and `Out` prepare a document before output. `PreRender(validate: true, lint: true)` makes that phase
explicit; `Validate()` and `Lint()` are available when a workflow needs an earlier checkpoint. Deliberately foreign XML
should use an appropriate profile or direct rendering strategy instead of pretending it is standard SVG.

For the standard vocabulary, use the
[MDN SVG element reference](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element). For Sevgi operations,
use the [DSL Catalog](@/dsl.md).
