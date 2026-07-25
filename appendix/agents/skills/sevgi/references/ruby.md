# Ruby Discipline

A `.sevgi` file is executable Ruby evaluated with Sevgi's drawing vocabulary. It is not a separate template language or
configuration format. Apply ordinary Ruby design and readability rules unless the compact DSL form is clearer.

- Use local variables for local drawing state and constants for genuine module/script invariants.
- Use Arrays, Hashes, ranges, loops, Enumerables, methods, and modules directly; do not recreate them as a second DSL.
- Separate input data from drawing behavior when that makes either easier to read or test.
- Extract reusable drawing behavior into ordinary methods or `SVG::Module`; use `SVG::Modules` for an owned nested
  module family.
- Prefer explicit arguments and return values over hidden global state, `eval`, monkey patches, or unnecessary
  metaprogramming.
- Keep side effects at the output boundary: build a document, then `Render`, `Save`, `Out`, `PDF`, or `PNG` deliberately.
- Preserve the surrounding project's Ruby version, naming, error, test, and formatting conventions.
- Hand-format `.sevgi` source for DSL readability. Do not run a broad Ruby formatter or autocorrect over `.sevgi`
  files when it would flatten or obscure the drawing.

## Preserve the DSL Shape

Let drawing code read as a Sevgi program rather than mechanically parenthesized Ruby. Use braces for a one-line block,
`do`/`end` for a multiline block, and omit optional parentheses from statement-like SVG elements and Sevgi operations.
Keep parentheses when they bind a compact block or chained expression clearly, as in
`SVG(:minimal) { circle r: 4 }.Render`.

Avoid:

```ruby
SVG(:minimal) do
  g({ id: "mark" }) do
    rect({ x: 2, y: 2, width: 12, height: 8 })
    circle({ cx: 8, cy: 6, r: 3 })
  end
end.Save("mark.svg")
```

Prefer:

```ruby
SVG :minimal do
  g id: "mark" do
    rect x: 2, y: 2, width: 12, height: 8
    circle cx: 8, cy: 6, r: 3
  end
end.Save "mark.svg"
```

The first form is valid Ruby; the problem is loss of the drawing vocabulary's visual rhythm.

## Callable Modules

Extend a Ruby module with `SVG::Module`. Its public instance methods are drawing steps; name the only step `call`, or
give several steps descriptive names. Private methods remain ordinary implementation helpers. A focused
`require "sevgi/graphics"` consumer uses `Sevgi::Graphics::Module` and `Sevgi::Graphics::Modules` instead of the full
facade constants.

`base` registers argument-independent invariant SVG content that runs once per invocation before the public drawing
steps. It is not general initialization or an ordering hook.

```ruby
Badge = Module.new do
  extend SVG::Module

  base { css ".badge" => { fill: "tomato" } }
  def call(label:) = text label, class: "badge"
end

SVG(:minimal) { Call Badge, label: "OK" }.Render
```

`Call` draws directly. On an Inkscape profile, `Group`, `Layer`, and `Layer!` wrap the same invocation in a group,
normal layer, or insensitive layer; `Symbols` expands the public steps into reusable symbols. Lowercase `layer` and
`layer!` instead open explicit layer blocks without invoking a module. Use `SVG::Modules` only when one namespace owns
a nested family of callable modules.

Ruby arithmetic is appropriate for domain data and values the program must know. It does not supersede the renderer
ownership rule in [drawing.md](drawing.md): idiomatic Ruby can still be the wrong layer for a rendering calculation.

Use the [Library Mode guide](https://sevgi.roktas.dev/library-mode/) for facade and module composition, and the
[Script Mode guide](https://sevgi.roktas.dev/script-mode/) for executable source behavior.
