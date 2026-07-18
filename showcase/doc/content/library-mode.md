+++
title = "Library Mode"
weight = 4
[extra]
group = "Start"
+++

`require "sevgi"` loads the toolkit and adds one global entry point: `SVG(...)`. Library code can start a document with
the same word used in a `.sevgi` script, but it does not pull every Sevgi helper into the application's method scope.

## Build and compose

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
```

`Append` and `Prepend` transfer existing elements into the document, so independently built fragments can become one
drawing. Here the background moves behind the original text, while the status icon moves after it. The same operations
also reorder elements that already share a parent.

Call `drawing.Render` when the surrounding application needs the SVG string. If you load only `sevgi/graphics`, the
component-level constructor is `Sevgi::Graphics.SVG`.

## Short and explicit forms

`SVG(...)` and `Sevgi.SVG(...)` are two names for the same constructor:

```ruby
require "sevgi"

short = SVG(:minimal) { circle r: 4 }
explicit = Sevgi.SVG(:minimal) { circle r: 4 }

short.Render == explicit.Render # => true
```

Use the short form when the surrounding code already makes Sevgi clear. Write `Sevgi.SVG` when another library defines
an `SVG` method or when you want the receiver visible at the call site. This only affects Ruby name resolution. Both
calls return the same kind of document.

`SVG` also exists as a constant naming the graphics component, so `SVG(:minimal)` calls the constructor while
`SVG::Module` looks up a constant. Parentheses make that distinction especially clear in ordinary Ruby code.

## Canvas and document profiles

Use a `Canvas` when dimensions, units, margins, and the resulting `viewBox` belong together. Its `size` is the outer
paper; `inner` is the remaining size after margins. The default viewBox shifts by the negative left and top margins, so
drawing coordinate `(0, 0)` starts at the inner area's top-left while the viewport still includes the margins:

```ruby
require "sevgi"

canvas = Sevgi::Graphics.canvas(:a4, margins: [12, 10])

drawing = SVG :minimal, canvas do
  rect width: canvas.inner.width, height: canvas.inner.height
end
```

A document profile owns SVG root attributes and preambles independently of the physical canvas. Anonymous profiles
are useful for one library object. Named profiles belong to a process-wide registry; reserve them for shared vocabulary
rather than per-request options:

```ruby
require "sevgi"

icon = Sevgi::Graphics.document(attributes: {viewBox: "0 0 24 24"})

SVG(icon) { circle cx: 12, cy: 12, r: 10 }.Render

Sevgi::Graphics.document(:badge, attributes: {viewBox: "0 0 40 16"})
SVG(:badge) { text "OK", x: 20, y: 12, "text-anchor": "middle" }.Render
```

The first argument to `SVG` selects the document profile; the optional second argument supplies the canvas. Root keyword
attributes are applied after both. Keep profile and canvas separate when several document dialects share one page size,
or one document dialect is rendered on several sizes.

## Library scope is smaller

The script runner puts the complete top-level API in its script scope, so `.sevgi` files can call `Paper`, `Grid`,
`Load`, and the output words directly. A normal `require "sevgi"` defines only `SVG` globally. Call other entry points
on `Sevgi`:

```ruby
require "sevgi"

Sevgi.Paper 85, 55, :card

card = SVG :minimal, :card do
  rect width: "100%", height: "100%", rx: 3
end

File.write("card.svg", card.Render)
```

The equivalent script can call `Paper`, `SVG`, and `Save` without qualification. In library mode, the application
decides where the rendered string goes.

## Import the full top level

If a class is dedicated to drawing, include `Sevgi` and use the script-style names inside it:

```ruby
require "sevgi"

badge = Class.new do
  include Sevgi

  def render(label)
    SVG(:minimal) { text label, x: 4, y: 14 }.Render
  end
end

badge.new.render("S")
```

`include Sevgi` adds the full top-level API to instances. You do not need it just to call `SVG(...)` after
`require "sevgi"`.

## Callable modules {#callable-modules}

Callable modules keep related drawing steps together without adding global methods. Before passing a module to
[`Call`](/dsl/#call), [`Group`](/dsl/#group), [`Layer`](/dsl/#layer-callable),
[`Layer!`](/dsl/#layer-callable-bang), or [`Symbols`](/dsl/#symbols), extend it with `SVG::Module`:

```ruby
status = Module.new do
  extend SVG::Module

  base { circle r: 10, fill: "seagreen" }
  def call(label:) = text label, y: 4, fill: "white", "text-anchor": "middle"
end

SVG :minimal, width: 24, height: 24 do
  g(transform: "translate(12 12)") { Call status, label: "OK" }
end.Render
```

`Module.new` creates an ordinary Ruby module. `extend SVG::Module` makes its public instance methods available as
drawing steps.

Name the method `call` when the module has one drawing step. If it has several public methods, each method becomes a
separate step. [`base`](/dsl/#base) registers shared, argument-independent drawing that runs before them. The wrapper
word decides whether Sevgi draws the result directly, puts it in a group or layer, or expands it into symbols.

`SVG::Module` is the short form of `Sevgi::SVG::Module`. When loading only `sevgi/graphics`, use
`Sevgi::SVG::Module` or the identical component-level name `Sevgi::Graphics::Module`.

### Module namespaces {#module-namespaces}

For a namespace that owns several drawing modules, use `extend SVG::Modules`. It applies the singular contract to the
namespace and its module constants, including descendants defined later:

```ruby
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

SVG :minimal do
  Call StatusIcons::Alert, x: 5
  Call StatusIcons::Ready, x: 15
end.Render
```

Sevgi leaves classes, autoloads, and modules merely aliased into the namespace alone. Extend an external module with
`SVG::Module` yourself when it should participate.
