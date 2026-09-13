# Derender

## Purpose

Some vector geometry is easier to create in a visual editor. Examples include a Bezier-heavy logo, a traced
illustration, and a hand-adjusted path. Derender brings that SVG/XML into the Sevgi element model. Editor-authored
geometry can then participate in Ruby-driven composition, styling, layout, and output.

Do not use Derender as a detour for ordinary shapes or relationships that are clearer in the Sevgi DSL. Use it when
SVG/XML is a real input artifact.

## Choose the Relationship

| Intent | Inline content | File | Result |
| --- | --- | --- | --- |
| Inspect an immutable parsed node | `SVG.Decompile` | `SVG.DecompileFile` | `Sevgi::Derender::Node` |
| Generate editable Sevgi Ruby source | `SVG.Derender` | `SVG.DerenderFile` | formatted Ruby String |
| Add the selected node to an existing tree | `SVG.Evaluate` | `SVG.EvaluateFile` | included element or `nil` |
| Add only the selected node's children | `SVG.EvaluateChildren` | `SVG.EvaluateChildrenFile` | frozen child snapshot |
| Include a selected file node inside an SVG block | — | `Include` | included element or `nil` |
| Include only a selected file node's children inside a block | — | `IncludeChildren` | frozen child snapshot |

Use `DerenderFile` when generated Ruby becomes the maintained source. Use `Include`, `EvaluateFile`, or their children
variants when the editor file remains the geometry source. Use `DecompileFile` to inspect names, attributes,
namespaces, metadata, and children. Choose one maintained representation. Do not maintain editor SVG and generated
Sevgi in parallel.

Keep the editor file as the geometry source and compose a selected group in Sevgi:

```ruby
SVG do
  Include "brand.svg", "logo", omit: :id
end.Save "badge.svg"
```

Add inline content to an existing document by passing the target explicitly:

```ruby
drawing = SVG :minimal
SVG.Evaluate '<circle id="mark" r="4"/>', drawing, omit: :id
drawing.Render
```

Generate Ruby for review and integration into the maintained source instead:

```ruby
source = SVG.DerenderFile "brand.svg", id: "logo", omit: :id
puts source
```

At the command line, `igves` prints generated Sevgi source. Use `igsev` from the umbrella gem only when the intended
result is normalized SVG produced by a complete SVG-to-Sevgi-to-SVG round trip. Both commands accept repeatable
`--omit ATTRIBUTE` and read standard input when the file is omitted or `-`. `igsev` is a structural formatter, not a
byte-preserving XML rewrite.

A selected subtree can produce a fragment rather than a standalone `.sevgi` script. Review the conversion. Then place
it inside the document or callable module that owns it. Do not rename an arbitrary fragment to `.sevgi`.

## Selection and Cleanup

Processing instructions retain their target, data, and order as inert XML markup. Custom entity references in the
selected subtree raise `Sevgi::ArgumentError` before target mutation. Predefined and numeric references remain valid.
Whole-document conversion rejects nodes after the root except whitespace. Explicit selection ignores unrelated siblings.

- Give reusable editor groups stable IDs and select one with `id:`. `Include` takes that ID as its second positional
  argument.
- Inspect an SVG tree with `SVG.DecompileFile` (or component-level `Sevgi::Derender.decompile_file`) before falling back
  to text search. Grep can mistake editor helpers, generated IDs, metadata, or unrelated layers for reusable artwork.
- Use `omit:` with one String/Symbol or an Array of exact, case-sensitive attribute names. Selection happens before
  omission, so the selecting ID can be removed.
- Namespace declarations remain intact, and omitting the `style` attribute does not remove `style` elements. Omit
  style, transform, or geometry attributes only when their behavior is intentionally replaced.
- Expect paths and other low-level editor geometry to remain low-level. Derender preserves the SVG tree. It cannot
  reconstruct the loops, modules, or design operations that originally created it.
- Treat parsing and executing as separate trust boundaries. Derender parses XML as data and direct evaluation builds
  graphics elements without executing generated Ruby. Do not pass generated source to Ruby's dynamic evaluation APIs
  (`eval`, `*_eval`, or `*_exec`), even when the input is trusted. When generated Ruby becomes the maintained
  representation, review it and integrate it statically into the owning source or callable module.
- After renaming or removing a selected id or source path, update its consumers, regenerate derived drawings, and check
  for stale references.

Script mode uses bare names such as `DerenderFile`. Library mode uses the `SVG.` facade. Component-only consumers use
the lowercase `Sevgi::Derender` methods and `_file` variants.

Read the [Derender guide](https://sevgi.roktas.dev/derender/) for the complete workflow and
[`sevgi-derender` YARD](https://www.rubydoc.info/gems/sevgi-derender) for exact signatures and failure contracts.
