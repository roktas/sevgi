+++
title = "Derender"
weight = 14
[extra]
group = "Toolkit"
+++

Not every useful vector drawing should be produced programmatically. A Bezier-heavy logo, traced illustration, or
hand-adjusted path may be easier and more faithful to author in a visual editor. Derender brings that SVG or XML into
Sevgi's element model, where editor-authored geometry can participate in Ruby-driven composition, styling, layout, and
output.

Use Derender when SVG/XML is a real input artifact, not as a detour for shapes or relationships that are clearer in the
Sevgi DSL. Convert inline content or a file, generate source, include part of it, or inspect its tree.

## The round trip

```text
SVG/XML content or file → immutable Derender node → Sevgi source → evaluated SVG tree
```

The conversion keeps element names, attributes, text, comments, CDATA, and child order. It represents the XML tree as
Ruby. It cannot recover the loops, helper methods, or other higher-level code that may have produced the original file.

| Operation family | Inline input | File input | Result | Existing target |
| --- | --- | --- | --- | --- |
| Inspect | `SVG.Decompile` | `SVG.DecompileFile` | immutable `Sevgi::Derender::Node` | no |
| Generate source | `SVG.Derender` | `SVG.DerenderFile` | formatted Ruby string | no |
| Include selection | `SVG.Evaluate` | `SVG.EvaluateFile` | included element or `nil` | yes |
| Include children | `SVG.EvaluateChildren` | `SVG.EvaluateChildrenFile` | frozen element snapshot | yes |

Choose source generation when the converted Ruby should become the maintained representation. Choose evaluation or
`Include` when the editor file should remain the source of its geometry and Sevgi should compose it at runtime.

Library code uses the capitalized facade operations. For example, a consumer can inspect a node and generate only that
subtree without installing script-mode names:

```ruby
xml = '<svg><g id="mark" style="fill: red"><rect width="4"/></g></svg>'
mark = SVG.Decompile(xml, id: "mark")
source = mark.derender

raise unless mark.name == "g"
raise unless source.include?("rect width: 4")
```

## Generate source

In a `.sevgi` script, `Derender` converts inline content and returns formatted Ruby:

```ruby
source = Derender '<path id="mark" d="M 0 0 L 8 3"/>', id: "mark"
puts source
```

Library code writes the same operation as `SVG.Derender(...)`.

Use `DerenderFile` when the source already lives on disk:

```ruby
source = DerenderFile "badge.svg", id: "mark"
```

The optional id selects one subtree. Without it, the document root is used. Pass one attribute name or an array to
`omit` when editor metadata should not survive the conversion:

```ruby
source = DerenderFile "badge.svg", id: "mark", omit: %i[id style]
```

Attribute names may be strings or symbols and match exactly across the selected subtree. Selection happens before
omission, so an id may select a node without appearing in the result. Namespace declarations and `style` elements are
preserved when attributes are omitted.

The companion `igves` command prints a file conversion from the shell and accepts a repeatable option:

```text
igves --omit id --omit style badge.svg
```

When normalized SVG is the desired result rather than generated Ruby, the umbrella `sevgi` gem provides `igsev`. It
performs the complete SVG-to-Sevgi-to-SVG round trip and accepts the same repeatable omission option:

```text
igsev --omit id --omit style badge.svg > normalized.svg
```

This is a structural formatter, not a byte-preserving XML rewrite: Sevgi rendering determines declaration, whitespace,
attribute spelling, and other serialized details.

## Inspect {#inspect}

`Decompile` stops one step earlier and returns an immutable node. The node owns snapshots of its attributes,
namespaces, metadata, content, and descendants:

```ruby
xml = <<~SVG
  <svg xmlns="http://www.w3.org/2000/svg" xmlns:_="https://sevgi.roktas.dev/meta">
    <g id="mark" _:role="icon"><rect width="4"/></g>
  </svg>
SVG

root = SVG.Decompile(xml)
mark = root.find("mark")

raise unless root.root?
raise unless root.namespaces["xmlns"] == "http://www.w3.org/2000/svg"
raise unless root.children.first.equal?(mark)
raise unless mark.attributes["id"] == "mark"
raise unless mark.meta["role"] == "icon"
raise unless mark.children.map(&:name) == ["rect"]
raise unless mark.derender.include?("rect width: 4")
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
SVG.Evaluate '<circle id="mark" r="4"/>', drawing, id: "mark"
drawing.Render
```

Use `EvaluateFile` or `EvaluateChildrenFile` for file input. All conversion and evaluation forms accept `omit`. Inside
an `SVG` block, the established `Include` and `IncludeChildren` drawing words remain convenient file-oriented forms
because their target is already the current element:

```ruby
SVG do
  Include "badge.svg", "mark", omit: %i[id style]
end
```

Applications depending only on `sevgi-derender` can use the lowercase component API under `Sevgi::Derender`:
`decompile`, `derender`, `evaluate`, and `evaluate_children` accept content; their `_file` counterparts accept paths.

All these APIs parse XML as data and build immutable snapshots or graphics elements; they do not execute the generated
Ruby. This is distinct from [`Sevgi.execute`](@/execution.md), which deliberately runs trusted Ruby with the process's
authority. Parsing untrusted XML still deserves normal resource limits, but it does not grant the source a Ruby
execution path.

The catalog links its Derender entries back here because selection, conversion, and evaluation all use this same
mechanism.
