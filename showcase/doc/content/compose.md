+++
title = "Compose"
weight = 11
[extra]
group = "Guides"
+++

Composition combines drawing parts without creating a new document type. Existing elements work well for fixed
fragments; callable modules add arguments, shared setup, and reusable drawing steps. Neither approach adds methods to
the document profile.

## Existing elements {#elements}

`Append` and `Prepend` move existing elements into a document. This is enough when each part can be built independently
and assembled later:

```ruby
require "sevgi"

drawing = SVG :minimal, width: 240, height: 64 do
  text "Payment received", x: 52, y: 27, "font-weight": "bold"
  text "$48.00", x: 52, y: 46, fill: "#166534"
end

status = SVG :minimal do
  g transform: "translate(28 32)" do
    circle r: 14, fill: "#16a34a"
    path d: "M -6 0 L -2 5 L 7 -6", fill: "none", stroke: "white", "stroke-width": 2
  end
end.first

background = SVG(:minimal) { rect width: 240, height: 64, rx: 10, fill: "#f0fdf4" }.first

drawing.Append status
drawing.Prepend background
drawing.Render
```

The background moves before the original text, while the status icon moves after it. The same operations also reorder
elements that already share a parent.

Use normal SVG `defs`, `symbol`, and `use` elements when the renderer should reuse one definition. `Duplicate` creates
independently editable copies instead. `Include` and `IncludeChildren` bring selected content from an external SVG file;
the [Derender guide](@/derender.md#evaluate) explains how that import works.

## Callable modules {#callable-modules}

Callable modules keep related drawing steps together and invoke them explicitly. `SVG.Module` creates an anonymous
module, makes its public methods callable drawing steps, and evaluates the definition block:

```ruby
require "sevgi"

Status = SVG.Module do
  base { circle r: 10, fill: "seagreen" }
  def call(label:) = text label, y: 4, fill: "white", "text-anchor": "middle"
end

SVG :minimal, width: 24, height: 24 do
  g(transform: "translate(12 12)") { Call Status, label: "OK" }
end.Render
```

Name the method `call` when the module has one drawing step. If it has several public methods, each method becomes a
separate step. `base` records argument-independent drawing that runs before those steps. Inherited base blocks run
parent first, followed by local blocks in registration order. The wrapper decides how Sevgi places the result:

| Wrapper | Result |
| --- | --- |
| `Call` | Draw directly in the current element |
| `Group` | Draw inside a group |
| `Layer` | Draw inside an Inkscape layer |
| `Layer!` | Draw inside an insensitive Inkscape layer |
| `Symbols` | Turn the public steps into reusable symbols |

`SVG.Module` works in both scripts and libraries. When loading only `sevgi/graphics`, create an ordinary `Module` and
extend it with `Sevgi::Graphics::Module`.

## Named modules {#named-modules}

Use the factory for a small callable whose state comes through arguments or surrounding Ruby values. Use an explicit
module declaration when the callable owns constants, nested modules, or other names. One outer namespace can hold both
individual callables and a nested family:

```ruby
require "sevgi"

module DrawingParts
  module Marker
    extend SVG::Module

    RADIUS = 6

    base { background }
    def call(label) = caption label

    private

    def background = circle r: RADIUS, fill: "tomato"
    def caption(label) = text label, y: 3, "text-anchor": "middle"
  end

  module StatusIcons
    extend SVG::Modules

    module Alert
      base { circle r: 5, fill: "tomato" }
      def call(x:) = text "!", x:, y: 3, "text-anchor": "middle"
    end

    module Ready
      def call(x:) = circle cx: x, r: 3, fill: "seagreen"
    end
  end
end

SVG :minimal do
  Call DrawingParts::Marker, "!"
  Call DrawingParts::StatusIcons::Alert, x: 18
  Call DrawingParts::StatusIcons::Ready, x: 30
end.Render
```

`Marker` exposes only `call` as a drawing step. Its private `background` and `caption` methods remain helpers, but they
can use drawing words such as `circle` and `text`.

Constants assigned directly inside an `SVG.Module` block belong to the surrounding Ruby scope, not to the module it
creates. In the explicit declaration above, `RADIUS` belongs to `DrawingParts::Marker`, and bare `RADIUS` inside `call`
finds it there. `SVG.Module` yields the new module as a block argument, so `mod::NAME = value` is possible. A normal
`def` does not capture that block argument or change where Ruby looks for constants, so the explicit form is clearer
when methods refer to module-owned constants.

`extend SVG::Modules` makes module constants inside `StatusIcons` callable, including descendants defined later.
Classes, autoloaded constants, and aliases to modules defined elsewhere are left unchanged. Extend an external module
with `SVG::Module` yourself when it should participate.

### Callable scope

A callable does not add methods to `SVG::Document::Base` or any profile derived from it. This makes the same drawing
code usable with `:minimal`, `:html`, `:inkscape`, and application-defined document types. The tradeoff is visible at
the call site: the drawing uses `Call` or another wrapper instead of a bare helper method.

Private and protected methods remain implementation helpers rather than drawing steps. Sevgi creates a fresh callable
receiver for every invocation. The receiver delegates drawing words to the current element, but it is not the document
object:

```ruby
Counter = SVG.Module do
  def call(x) = text next_count.to_s, x: x

  private

  def next_count
    @count = (@count || 0) + 1
  end
end

SVG :minimal do
  Call Counter, 0
  Call Counter, 12
end.Render
```

The private helper works, but both calls draw `1` because `@count` belongs to a new callable receiver each time. Pass
changing values as arguments. When a helper must read or change document state, keep it on a
[document type or mixture](@/documents.md#document-types).

## Forward nested content {#content}

A callable method can accept its caller's block and forward it to the element that owns the nested content. Sevgi
elements accept initial text and a block together, so inline children such as `tspan` remain nested under `text`:

```ruby
require "sevgi"

RadialLabel = SVG.Module do
  def call(value, center:, angle:, radius:, **attributes, &content)
    cx, cy = center
    x = cx + (radius * Sevgi::F.cos(angle))
    y = cy + (radius * Sevgi::F.sin(angle))
    defaults = {x:, y:, fill: "black", "text-anchor": "middle"}

    text value, defaults, attributes, &content

    [x, y]
  end
end

drawing = SVG :minimal, width: 500, height: 500 do
  Call RadialLabel, "Hello, World!", center: [250, 250], angle: 45, radius: 100 do
    tspan "cruel"
  end
end

drawing.Render
```

The coordinate pair returned by `call` remains available from `Call`. Ruby still looks up constants from where the
method was defined: library code uses `Sevgi::F`, while executable `.sevgi` scripts may use the promoted `F` constant.
