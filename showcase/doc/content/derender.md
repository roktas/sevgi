+++
title = "Derender"
weight = 14
[extra]
group = "Toolkit"
+++

Derender turns SVG or XML into readable Sevgi source. It is handy when a drawing starts in a visual editor but needs to
end up in code. Convert inline content or a file, then regenerate it, include part of it, or inspect its tree.

## The round trip

```text
SVG/XML content or file → immutable Derender node → Sevgi source → evaluated SVG tree
```

The conversion keeps element names, attributes, text, comments, CDATA, and child order. It represents the XML tree as
Ruby. It cannot recover the loops, helper methods, or other higher-level code that may have produced the original file.

## Generate source

In a `.sevgi` script, `Derender` converts inline content and returns formatted Ruby:

```ruby
source = Derender '<path id="mark" d="M 0 0 L 8 3"/>', id: "mark"
puts source
```

Use `DerenderFile` when the source already lives on disk:

```ruby
source = DerenderFile "badge.svg", id: "mark"
```

The optional id selects one subtree. Without it, the document root is used. The companion `igves` command prints a
file conversion from the shell.

## Inspect {#inspect}

`Decompile` stops one step earlier and returns an immutable node:

```ruby
node = Decompile '<circle id="mark" r="4"/>', id: "mark"
puts node.name
puts node.attributes
```

The file counterpart is explicit:

```ruby
node = DecompileFile "badge.svg", id: "mark"
```

Use these methods when you need to examine a selection, its attributes, or its children without generating source.

## Evaluate and include {#evaluate}

`Evaluate` imports inline content directly into an existing SVG tree. `EvaluateChildren` imports only the selected
node's children:

```ruby
drawing = SVG :minimal
Evaluate '<circle id="mark" r="4"/>', drawing, id: "mark"
drawing.Render
```

Use `EvaluateFile` or `EvaluateChildrenFile` for file input. Inside an `SVG` block, the established `Include` and
`IncludeChildren` drawing words remain convenient file-oriented forms because their target is already the current
element.

Library code has the same matrix under `Sevgi::Derender`: `decompile`, `derender`, `evaluate`, and
`evaluate_children` accept content; their `_file` counterparts accept paths.

The catalog links its Derender entries back here because selection, conversion, and evaluation all use this same
mechanism.
