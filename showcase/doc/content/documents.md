+++
title = "Documents"
weight = 10
[extra]
group = "Guides"
+++

Documents are SVG element trees built with a canvas and a document profile. This page explains those parts, shows how
to define application-specific profiles and document types, and describes the checks that run before output. Reusable
drawing code that does not belong to one document type is covered in [Compose](@/compose.md).

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

Lowercase calls add SVG elements to the tree. Capitalized words create supporting values or operate on elements. In
library code, operations outside the block use the `SVG.` prefix; types and namespaces use `SVG::`.

## Canvas {#canvas}

A canvas keeps dimensions, units, margins, and the resulting `viewBox` together. Its `size` is the outer paper; `inner`
is the size left after margins. The default `viewBox` shifts by the negative left and top margins, so drawing coordinate
`(0, 0)` starts at the inner area's top-left while the viewport still includes the margins:

```ruby
require "sevgi"

canvas = SVG.Canvas :a4, margins: [12, 10]

drawing = SVG :minimal, canvas do
  rect width: canvas.inner.width, height: canvas.inner.height
end
```

The canvas describes physical size and drawing coordinates. A profile describes root metadata, preambles, and
available document methods. Keep them separate when several profiles share one page size or one profile uses several
sizes.

## Profiles {#profiles}

A profile controls document metadata and extra DSL capabilities, not canvas size or checking policy. All four profiles
use the same validation and lint lifecycle.

| Profile | Preamble | Root metadata | Additional DSL |
| --- | --- | --- | --- |
| `:minimal` | none | none | common document DSL |
| `:default` | XML declaration | SVG namespace | common document DSL |
| `:html` | none | SVG namespace | common document DSL |
| `:inkscape` | XML declaration | SVG and editor namespaces; crisp edges | `Draw`, `Hatch`, and editor/RDF helpers |

Use `:minimal` for compact output, `:default` for a standalone SVG file, `:html` for SVG embedded in HTML, and
`:inkscape` when editor metadata or its additional helpers belong to the drawing.
The Inkscape root adds Sevgi, Inkscape, and Sodipodi namespaces plus `shape-rendering="crispEdges"`. The presence of
`Draw` and `Hatch` on `:inkscape` is a convenience default, not an Inkscape format requirement.

`Minimal` and `Default` are sibling concrete profiles. `Minimal` adds no metadata and is not the base of the other
profiles. `SVG::Document::Base` supplies the drawing methods shared by all profiles, but is not itself a selectable
named profile.

## Define a profile {#define}

`SVG.Document` creates a profile class derived from `SVG::Document::Base`. Omit the name for a private, one-off class;
give it a name when other code should select it by symbol:

```ruby
require "sevgi"

icon = SVG.Document attributes: {viewBox: "0 0 24 24"}
SVG(icon) { circle cx: 12, cy: 12, r: 10 }.Render

SVG.Document :badge, attributes: {viewBox: "0 0 40 16"}
SVG(:badge) { text "OK", x: 20, y: 12, "text-anchor": "middle" }.Render
```

Anonymous profiles stay local to the code that holds their class. Named profiles are registered for the current Ruby
process, so use them for shared document vocabulary rather than request-specific options. Repeating `SVG.Document`
with the same name and metadata is safe; conflicting metadata raises an error. `SVG.Document!` explicitly replaces an
existing definition.

Use this factory when root attributes and preambles are the only differences. When a document also owns DSL methods,
define a document type or add a mixture to the returned profile class.

## Document types {#document-types}

A subclass of `SVG::Document::Base` is an unnamed document type with the common SVG DSL. Pass the class itself to
`SVG`. Methods defined on it are available as bare drawing words and are inherited by its subclasses. `SVG.Mixin` adds
methods after a class has been created, which is useful when a separate library owns the extension.

Sevgi builds its own profiles from the same pieces: profile classes inherit from `Base` or another profile, and
profile-specific drawing methods arrive through mixtures.

```ruby
require "sevgi"

Flowchart = Class.new(SVG::Document::Base) do
  def Node(label, x:, y:)
    g transform: "translate(#{x} #{y})" do
      rect x: -32, y: -12, width: 64, height: 24, rx: 4, fill: "white", stroke: "black"
      text label, y: 4, "text-anchor": "middle"
    end
  end
end

SVG.Mixin Flowchart do
  def Link(from:, to:, **attributes)
    x1, y1 = from
    x2, y2 = to
    line x1:, y1:, x2:, y2:, stroke: "black", **attributes
  end
end

drawing = SVG Flowchart, width: 200, height: 80 do
  Link from: [77, 40], to: [113, 40]
  Node "Parse", x: 45, y: 40
  Node "Render", x: 145, y: 40
end

drawing.Render
```

`Flowchart` owns `Node`; the mixture adds `Link`. Both run as document methods, so they can use the document's DSL and
private helpers directly. Their names become methods of this document type.

The choice depends on what the application is defining:

| Need | Use | Effect |
| --- | --- | --- |
| Different root metadata or preambles | `SVG.Document` | Creates an anonymous or registered profile class |
| A new document type that always owns certain methods | subclass `SVG::Document::Base` | Methods belong to the type and its subclasses |
| Add named or application-defined methods to an existing type | `SVG.Mixin` | Methods join the target type and its subclasses |

`SVG.Mixin` also accepts Sevgi's named mixtures. For example, a private type can use `Hatch` without adopting the
Inkscape profile's metadata:

```ruby
profile = Class.new(SVG::Document::Base)
SVG.Mixin :Hatch, profile
region = Sevgi::Geometry::Rect[24, 12]

SVG(profile) do
  Draw region.lines, stroke: "silver"
  Hatch region, angle: 30, step: 3, stroke: "black"
end.Render
```

Targeting `SVG::Document::Base` itself changes every descendant profile for the whole process. Subclass it first when
the extension should stay local. Base subclasses and `SVG.Mixin` change what a document type can do. Use
[`SVG.Module`](@/compose.md#callable-modules) when drawing code should work across document types without adding methods
to any of them.

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

| Input | Use | Behavior |
| --- | --- | --- |
| Ordinary text argument | `text "A & B"` | encoded automatically |
| Explicit reusable text content | `Content.encoded` | XML text-encoded |
| Literal text body in a CDATA section | `Content.cdata` | CDATA terminators split safely |
| CSS rules expressed as a Hash | `Content.css` | rendered as CSS inside CDATA |
| Already serialized trusted markup | `Content.verbatim` | deliberately unescaped; caller owns well-formedness and escaping |

```ruby
drawing = SVG :minimal do
  text "A & B"
  text SVG::Content.encoded("A & B")
  style SVG::Content.cdata(".note { fill: red; }")
  style SVG::Content.css(".note" => {fill: "red"})
  g SVG::Content.verbatim("<title>trusted markup</title>")
end

drawing.Render
```

Advanced consumers may subclass `SVG::Content` and implement `render(output, depth)`. The rendering engine ignores the
method's return value. A custom implementation must escape any data it inserts into markup; use
`SVG::Content.encoded(...).to_s` rather than interpolating caller text directly.

## Validation lifecycle

`Render`, `Save`, and `Out` prepare a document before writing it. Call `PreRender(validate: true, lint: true)` to run
that phase yourself, or use `Validate()` and `Lint()` for an earlier check. For non-SVG XML, choose a suitable document
profile or render directly instead of running the standard SVG checks.

{{ mermaid(name="validation") }}

For the standard vocabulary, use the
[MDN SVG element reference](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element). For Sevgi operations,
use the [DSL Catalog](@/dsl.md).
