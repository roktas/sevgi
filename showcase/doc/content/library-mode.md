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

class Badge
  include Sevgi

  def render(label)
    SVG(:minimal) { text label, x: 4, y: 14 }.Render
  end
end
```

Prefer `Sevgi.SVG` at broad application boundaries; `include Sevgi` intentionally adds the top-level entry points to
the receiver.

## Callable modules {#callable-modules}

Callable drawing modules package receiver-free DSL steps without turning them into global methods:

```ruby
dot = Module.new do
  extend Sevgi::SVG::Module

  base { circle r: 5, fill: "gold" }
  def call(x:) = circle(cx: x, r: 2, fill: "black")
end

Sevgi.SVG(:minimal) { Call dot, x: 8 }.Render
```

Use `base` for shared drawing that runs before public drawing methods. Use `Call`, `Group`, `Layer`, or `Symbols`
depending on the wrapper the document needs.
