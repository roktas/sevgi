+++
title = "Choose a Mode"
weight = 2
[extra]
group = "Start"
+++

Both modes build the same SVG documents. Use a `.sevgi` script when the drawing is the program. Use the Ruby API when a
larger application owns the drawing.

## Script mode

A script gets the top-level DSL automatically and can be run directly:

```ruby
#!/usr/bin/env -S ruby -S sevgi

SVG :minimal do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save
```

Scripts work well for generated assets, plotter input, and build jobs. [Script Mode](@/script-mode.md) covers the
runner and its top-level API.

## Library mode

`require "sevgi"` provides the same short `SVG` entry point. Moving a drawing into an application does not change its
spelling:

```ruby
require "sevgi"

drawing = SVG :minimal do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end

File.write("badge.svg", drawing.Render)
```

The surrounding scope is different. A Sevgi script gets the full top-level API and output helpers. A Ruby application
gets the short `SVG` constructor, then keeps the resulting document. Other entry points remain available through
`Sevgi`, for example `Sevgi.Paper(...)`. You can also write `Sevgi.SVG(...)`; it builds the same document as `SVG(...)`.

Library mode fits code that returns SVG in an HTTP response, compares it in a test, or writes it through an existing
storage layer. [Library Mode](@/library-mode.md) explains the namespace choices.

## Do examples need both forms?

Usually no. Repeating every example obscures the idea being taught. This site labels context in the DSL catalog and
uses paired examples only where the forms behave differently, such as document construction, loading, and output.
Inside an `SVG` block, both modes use the same drawing words. Qualification only changes how Ruby finds the entry point.
