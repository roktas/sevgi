+++
title = "Choose a Mode"
weight = 2
[extra]
group = "Start"
+++

Sevgi has one drawing model and two comfortable entry points. Choose by ownership: use a `.sevgi` script when the
drawing is the program; use the Ruby API when the drawing is part of a larger program.

## Script mode

A script gets the top-level DSL automatically and can be run directly:

```ruby
#!/usr/bin/env -S ruby -S sevgi

SVG :minimal do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save
```

This is the shortest path for generated assets, plotter inputs, templates, and build steps. See [Script Mode](@/script-mode.md).

## Library mode

An application can keep names explicit:

```ruby
require "sevgi"

drawing = Sevgi.SVG(:minimal) do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end

File.write("badge.svg", drawing.Render)
```

This works well in services, tests, gems, and applications that already own their output lifecycle. See
[Library Mode](@/library-mode.md).

## Do examples need both forms?

Usually no. Repeating every example obscures the idea being taught. This site labels context in the DSL catalog and
shows paired examples only where the boundary matters—document construction, reusable modules, loading, and output.
Inside an `SVG` block the drawing vocabulary is the same in both modes.
