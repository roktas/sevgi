+++
title = "Derender"
weight = 14
[extra]
group = "Toolkit"
+++

Derender turns existing SVG or XML back into readable Sevgi source. It is useful at the boundary with visual editors:
start from an artifact, recover a compact Ruby representation, then decide whether to regenerate, include, or inspect it.

## The round trip

```text
SVG/XML file → immutable Derender node → Sevgi source → evaluated SVG tree
```

The conversion preserves element names, attributes, text, comments, CDATA, and child order. Generated source is an
honest representation of the XML tree; it is not an attempt to rediscover the higher-level program that originally
produced it.

## Generate source

In a `.sevgi` script, `Derender` reads a file and returns formatted Ruby:

```ruby
source = Derender "badge.svg", "mark"
puts source
```

The optional id selects one subtree. Without it, the document root is used. The companion `igves` command prints the
same conversion from the shell.

## Inspect {#inspect}

`Decompile` stops one step earlier and returns an immutable node:

```ruby
node = Decompile "badge.svg", "mark"
puts node.name
puts node.attributes
```

Use this when selection, attributes, or tree structure matter more than generated source.

## Evaluate and include {#evaluate}

`Include` evaluates a selected node under the current SVG element; `IncludeChildren` imports only its children:

```ruby
SVG(:minimal) do
  g(id: "imported") { Include "badge.svg", "mark" }
end.Render
```

At library level the corresponding APIs are `Sevgi::Derender.derender_file`, `decompile_file`, `evaluate_file`, and
`evaluate_children_file`. Prefer those explicit methods when an application already owns file IO and document objects.

Derender's catalog entries stay brief and link here because selection, conversion, and evaluation are one mechanism,
not three unrelated DSL tricks.
