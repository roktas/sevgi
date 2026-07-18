+++
title = "Library Mode"
weight = 3
[extra]
group = "Start"
+++

`require "sevgi"` loads two complementary entry points: the global `SVG(...)` document builder and the `SVG` facade.
Facade operations use capitalized method names such as `SVG.Canvas`, `SVG.Document`, and `SVG.Derender`; constants and
types use double colons, such as `SVG::Canvas`. Library code gets this explicit SVG vocabulary without pulling every
Sevgi helper into the application's method scope.

Use the [Execution](@/execution.md) API when library code needs to run a complete trusted `.sevgi` program rather than
construct a document directly.

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

## Facade grammar

The method/constant distinction is deliberate:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 24, height: 24, unit: :px
drawing = SVG(:minimal, canvas) { circle cx: 12, cy: 12, r: 10 }

canvas.is_a?(SVG::Canvas) # => true
drawing.Render
```

`SVG(...)` invokes the global document-builder method. `SVG.Canvas(...)` invokes a facade operation.
`SVG::Canvas` names the returned type. The facade does not repeat the receiver as `SVG.SVG(...)`.

The same top-level operations also exist on `Sevgi` because script execution and `include Sevgi` use that complete
toolkit surface. `Sevgi.SVG(...)` and `Sevgi.Canvas(...)` are valid, but the `SVG` facade is the canonical receiver for
ordinary SVG library work. Execution stays separate as `Sevgi.execute` and `Sevgi.execute_file`.

## Canvas and document profiles

Use a `Canvas` when dimensions, units, margins, and the resulting `viewBox` belong together. Its `size` is the outer
paper; `inner` is the remaining size after margins. The default viewBox shifts by the negative left and top margins, so
drawing coordinate `(0, 0)` starts at the inner area's top-left while the viewport still includes the margins:

```ruby
require "sevgi"

canvas = SVG.Canvas :a4, margins: [12, 10]

drawing = SVG :minimal, canvas do
  rect width: canvas.inner.width, height: canvas.inner.height
end
```

A document profile owns SVG root attributes and preambles independently of the physical canvas. Anonymous profiles
are useful for one library object. Named profiles belong to a process-wide registry; reserve them for shared vocabulary
rather than per-request options. The [document-profile matrix](@/svg.md#document-profiles) compares the four built-in
choices and explains the advanced common extension layer.

```ruby
require "sevgi"

icon = SVG.Document attributes: {viewBox: "0 0 24 24"}

SVG(icon) { circle cx: 12, cy: 12, r: 10 }.Render

SVG.Document :badge, attributes: {viewBox: "0 0 40 16"}
SVG(:badge) { text "OK", x: 20, y: 12, "text-anchor": "middle" }.Render
```

The first argument to `SVG` selects the document profile; the optional second argument supplies the canvas. Root keyword
attributes are applied after both. Keep profile and canvas separate when several document dialects share one page size,
or one document dialect is rendered on several sizes.

## The same vocabulary with a receiver

The script runner promotes operations such as `Paper`, `Canvas`, and `Grid` into its managed scope. Library code uses
the same capitalized words on the facade:

```ruby
require "sevgi"

SVG.Paper 85, 55, :card
canvas = SVG.Canvas :card, margins: 4

card = SVG :minimal, canvas do
  rect width: "100%", height: "100%", rx: 3
end

File.write("card.svg", card.Render)
```

The equivalent script drops only the facade receiver: `Paper(...)` and `Canvas(...)` become bare words, while
`SVG(...)` and the drawing block stay unchanged. In library mode, the application usually decides where the rendered
string goes.

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

## Focused graphics component

Applications that depend only on `sevgi-graphics` use its conventional lowercase component API. This focused require
does not install the full `SVG` facade:

```ruby
require "sevgi/graphics"

canvas = Sevgi::Graphics.canvas width: 24, height: 24, unit: :px
drawing = Sevgi::Graphics.SVG(:minimal, canvas) { circle cx: 12, cy: 12, r: 10 }
```

Use this form when the smaller gem dependency is the goal. Do not mix its lowercase constructors into the facade
dialect; `SVG.Canvas` is the corresponding full-toolkit spelling.

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

`SVG::Module` aliases the graphics component's callable-module contract. When loading only `sevgi/graphics`, the facade
is not installed; use `Sevgi::Graphics::Module`.

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
