+++
title = "Derender"
weight = 14
[extra]
group = "Toolkit"
+++

Derender turns SVG or XML into readable Sevgi source. It is handy when a drawing starts in a visual editor but needs to
end up in code. Convert the file, then regenerate it, include part of it, or inspect its tree.

## The round trip

```text
SVG/XML file → immutable Derender node → Sevgi source → evaluated SVG tree
```

The conversion keeps element names, attributes, text, comments, CDATA, and child order. It represents the XML tree as
Ruby. It cannot recover the loops, helper methods, or other higher-level code that may have produced the original file.

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

Use `Decompile` when you need to examine a selection, its attributes, or its children without generating source.

## Evaluate and include {#evaluate}

`Include` evaluates a selected node under the current SVG element; `IncludeChildren` imports only its children:

```ruby
SVG(:minimal) do
  g(id: "imported") { Include "badge.svg", "mark" }
end.Render
```

Library code can call `Sevgi::Derender.derender_file`, `decompile_file`, `evaluate_file`, and `evaluate_children_file`.
These methods fit applications that already manage their own files and document objects.

The catalog links its Derender entries back here because selection, conversion, and evaluation all use this same
mechanism.
