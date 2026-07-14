+++
title = "Library Mode"
weight = 4
[extra]
group = "Start"
+++

`require "sevgi"` loads the complete toolkit. `Sevgi.SVG` is the explicit, namespaced document constructor; it accepts
the same profile, canvas, attributes, and block as the script-mode `SVG` word.

## Build and render

```ruby
require "sevgi"

document = Sevgi.SVG(:minimal, width: 120, height: 40) do
  rect width: 120, height: 40, rx: 8, fill: "midnightblue"
  text "Sevgi", x: 60, y: 25, fill: "white", "text-anchor": "middle"
end

svg = document.Render
```

Rendering returns a string. The application can write it, return it from an HTTP endpoint, compare it in a test, or
pass it to another component. `Sevgi::Graphics.SVG` remains the component-level constructor when only graphics is loaded.

## Import the top level deliberately

For a small Ruby object that benefits from script-like spelling, include `Sevgi`:

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

Prefer `Sevgi.SVG` at broad application boundaries; `include Sevgi` intentionally adds the top-level entry points to
the receiver.

## Callable modules {#callable-modules}

Callable drawing modules package receiver-free DSL steps without turning them into global methods. Every module passed
to [`Call`](/dsl/#call), [`Group`](/dsl/#group), [`Layer`](/dsl/#layer-callable),
[`Layer!`](/dsl/#layer-callable-bang), or [`Symbols`](/dsl/#symbols) must extend `Sevgi::Module`:

```ruby
dot = Module.new do
  extend Sevgi::Module

  base { circle r: 5, fill: "gold" }
  def call(x:) = circle(cx: x, r: 2, fill: "black")
end

Sevgi.SVG(:minimal) { Call dot, x: 8 }.Render
```

Here `Module.new` creates a plain Ruby module; `extend Sevgi::Module` equips it with Sevgi's callable drawing contract.

The contract makes public instance methods callable drawing steps. A single-step module conventionally names its method
`call`; a module with several public methods exposes each one. [`base`](/dsl/#base) registers shared, argument-independent
drawing that runs once before those methods. The wrapper word determines whether the result is drawn directly, grouped,
layered, or expanded into symbols.

The full toolkit exposes the short `Sevgi::Module` name. When loading only `sevgi/graphics`, use the identical
`Sevgi::Graphics::Module` contract (`Sevgi::SVG::Module` is its SVG-namespace alias).

### Module namespaces {#module-namespaces}

For a namespace containing several drawing modules, `extend Sevgi::Modules` is the convenience form. It applies the
singular contract to the namespace and recursively to module constants it owns, including descendants defined later:

```ruby
module StatusIcons
  extend Sevgi::Modules

  module Alert
    base { circle r: 5, fill: "tomato" }
    def call(x:) = text("!", x:, y: 3, "text-anchor": "middle")
  end

  module Ready
    def call(x:) = circle(cx: x, r: 3, fill: "seagreen")
  end
end

Sevgi.SVG(:minimal) do
  Call StatusIcons::Alert, x: 5
  Call StatusIcons::Ready, x: 15
end.Render
```

This propagation is deliberately bounded: classes, autoloads, and modules merely aliased into the namespace are left
alone. Extend an individual external module with `Sevgi::Module` explicitly when it should participate.
