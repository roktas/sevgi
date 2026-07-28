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

Promoted top-level operations also exist on `Sevgi` because script execution and `include Sevgi` use that complete
toolkit surface. `Sevgi.SVG(...)` and `Sevgi.Canvas(...)` are valid, but the `SVG` facade is the canonical receiver for
ordinary SVG library work. `SVG.Module` is a facade-only convenience constructor. Execution stays separate as
`Sevgi.execute` and `Sevgi.execute_file`.

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

### Add helpers to a document class {#document-subclasses}

A library can create a `SVG::Document::Base` subclass when all documents of that type need the same helper methods.
Pass the class directly to `SVG`. This keeps the helpers on that class instead of adding them to Sevgi's built-in
document classes or registering a profile name for the whole process:

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

`Flowchart` defines `Node` itself. `SVG.Mixin` adds `Link` after the class has been created. Both methods can be called
directly in a `Flowchart` drawing, and subclasses of `Flowchart` inherit them.

Use a [callable module](#callable-modules) when the same drawing helper should work with different document classes
without adding methods to them. Calling `SVG.Mixin` on `SVG::Document::Base` adds the methods to every subclass. The
[document-profile guide](@/svg.md#document-profiles) shows this with a named mixture.

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

Callable modules keep related drawing steps together without adding global methods. Use `SVG.Module` to build an
anonymous callable before passing it to [`Call`](/dsl/#call), [`Group`](/dsl/#group),
[`Layer`](/dsl/#layer-callable), [`Layer!`](/dsl/#layer-callable-bang), or [`Symbols`](/dsl/#symbols):

```ruby
status = SVG.Module do
  base { circle r: 10, fill: "seagreen" }
  def call(label:) = text label, y: 4, fill: "white", "text-anchor": "middle"
end

SVG :minimal, width: 24, height: 24 do
  g(transform: "translate(12 12)") { Call status, label: "OK" }
end.Render
```

`SVG.Module` creates an ordinary Ruby module and installs the callable contract before evaluating its optional
definition. This makes `base` available inside the block and records public instance methods as drawing steps. To
configure an existing module instead, use `extend SVG::Module` explicitly. Constants assigned inside an `SVG.Module`
block belong to the surrounding Ruby scope, not to the module it creates. Use an explicit `module` declaration when the
callable owns constants or nested modules.

Name the method `call` when the module has one drawing step. If it has several public methods, each method becomes a
separate step. [`base`](/dsl/#base) registers shared, argument-independent drawing that runs before them. The wrapper
word decides whether Sevgi draws the result directly, puts it in a group or layer, or expands it into symbols.

`SVG::Module` aliases the graphics component's callable-module contract. When loading only `sevgi/graphics`, the facade
and its `SVG.Module` convenience constructor are not installed; create an ordinary `Module` and extend it with
`Sevgi::Graphics::Module`.

### Forward nested content {#callable-content}

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

The returned coordinate pair remains available from `Call` when the caller needs it. The definition block keeps normal
Ruby lexical constant lookup: ordinary library code uses `Sevgi::F`, while executable `.sevgi` scripts may use the
promoted `F` constant.

### Three ways to add drawing helpers {#callable-ownership}

The [Flowchart example](#document-subclasses) and `RadialLabel` show three ways to add drawing helpers:

| Option | Good for | Cost |
| --- | --- | --- |
| `Class.new(SVG::Document::Base)` | Documents that always need the same helper methods | The methods become part of that class and its subclasses |
| `SVG.Mixin` | Adding methods to an existing document class | It changes that class and its subclasses |
| `SVG.Module` | Reusing drawing code without adding methods to document classes | It requires `Call`, and every public method is a drawing step |

`SVG.Module` can use private and protected helpers. Every public method is a drawing step, so helper-only methods must be
private or protected. These helpers can call SVG methods, but they do not run as methods of the SVG document.

Use `SVG.Module` when the helper should work with different document classes. Create a subclass when its helpers should
always be part of that document type. Use `SVG.Mixin` to add helpers after a class has been defined or from another
library.

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
