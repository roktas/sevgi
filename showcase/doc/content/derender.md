+++
title = "Derender"
weight = 14
[extra]
group = "Guides"
+++

Some vector drawings are easier to create in a visual editor. Examples include a Bezier-heavy logo, a traced
illustration, and a hand-adjusted path. Derender brings that SVG or XML into Sevgi's element model. The geometry can
then participate in Ruby-driven composition, styling, layout, and output.

Use Derender when SVG/XML is a real input artifact, not as a detour for shapes or relationships that are clearer in the
Sevgi DSL. Convert inline content or a file, generate source, include part of it, or inspect its tree.

## The round trip

{{<mermaid name="derender" />}}

The conversion keeps element names, attributes, text, comments, CDATA, processing instructions, and child order. It represents the XML tree as
Ruby. It cannot recover loops, helper methods, or other higher-level source code from the original file.

Processing instructions retain their target and data as XML markup. Sevgi does not execute them.
Custom entity references in the selected subtree raise `Sevgi::ArgumentError` before inclusion changes the target.
Predefined references such as `&amp;` and numeric references such as `&#65;` remain valid.

Whole-document conversion rejects comments and processing instructions after the root element. Trailing whitespace is
valid. An explicit `id:` selects only that subtree and ignores unrelated document siblings.

| Operation family | Inline input | File input | Result | Existing target |
| --- | --- | --- | --- | --- |
| Inspect | `SVG.Decompile` | `SVG.DecompileFile` | immutable `Sevgi::Derender::Node` | no |
| Generate source | `SVG.Derender` | `SVG.DerenderFile` | formatted Ruby string | no |
| Include selection | `SVG.Evaluate` | `SVG.EvaluateFile` | included element or `nil` | yes |
| Include children | `SVG.EvaluateChildren` | `SVG.EvaluateChildrenFile` | frozen element snapshot | yes |

Choose source generation when the converted Ruby becomes the maintained representation. Choose evaluation or
`Include` when the editor file remains the geometry source. Sevgi then composes it at runtime.

Library code uses the capitalized facade operations. For example, a consumer can inspect a node and generate only that
subtree without adding the script runner's top-level names:

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

The String returned by `Derender`, `DerenderFile`, or `Node#derender` is ordinary Ruby source. Review it and place it in
a maintained `.sevgi` or `.rb` file. Do not pass it to `eval`, an `*_eval` method, or an `*_exec` method. If the SVG
file remains authoritative, use `Evaluate*` or `Include*`. Sevgi then imports it as XML data.

The optional id selects one subtree. Without it, the conversion uses the document root. Pass one attribute name or an
array to `omit` to remove unwanted editor metadata:

```ruby
source = DerenderFile "badge.svg", id: "mark", omit: %i[id style]
```

Attribute names can be strings or symbols. They match exactly across the selected subtree. Selection happens before
omission, so an id can select a node without appearing in the result. Attribute omission preserves namespace
declarations and `style` elements.

The companion `igves` (`sevgi` reversed) command prints a file conversion from the shell and accepts a repeatable
option:

```text
igves --omit id --omit style badge.svg
```

Both conversion commands read standard input when the file is omitted or `-`, which makes the same conversion usable
in a pipeline:

```text
igves --omit id < badge.svg
```

When normalized SVG is the desired result rather than generated Ruby, the umbrella `sevgi` gem provides `igsev`
(`igves` + `sevgi`). It performs the complete SVG-to-Sevgi-to-SVG round trip and accepts the same repeatable omission
option:

```text
igsev --omit id --omit style badge.svg > normalized.svg
```

This is a structural formatter, not a byte-preserving XML rewrite. Sevgi rendering determines declarations,
whitespace, attribute spelling, and other serialized details.

## Inspect {{ "{#inspect}" }}

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

## Evaluate and include {{ "{#evaluate}" }}

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

Applications depending only on `sevgi-derender` can use the lowercase API under `Sevgi::Derender`. `decompile`,
`derender`, `evaluate`, and `evaluate_children` accept content. Their `_file` counterparts accept paths.

All these APIs parse XML as data. They build immutable snapshots or graphics elements without executing generated Ruby.
This differs from [`Sevgi.execute`](@/usage.md#execute), which runs trusted Ruby with the process's authority. Apply
normal resource limits when parsing untrusted XML. Parsing alone does not grant the source a Ruby execution path.

The catalog links its Derender entries back here because selection, conversion, and evaluation all use this same
mechanism.
