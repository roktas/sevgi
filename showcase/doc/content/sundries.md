+++
title = "Sundries"
weight = 13
[extra]
group = "Toolkit"
+++

Sundries contains small cross-component objects that support layout and output. These are regular Ruby objects rather
than a second drawing DSL; each section starts with the task, then introduces the object that models it.

## Grid {#grid}

`Grid` fits major and minor ruler intervals into a canvas. It is available as a top-level constructor in scripts:

```ruby
canvas = SVG.canvas(width: 60, height: 40, margins: [4, 6])
grid = Grid canvas, unit: 1, multiple: 5

SVG(:inkscape, grid.canvas) do
  grid.x.major.lines.each { Draw it, stroke: "silver" }
  grid.y.major.lines.each { Draw it, stroke: "silver" }
end.Render
```

The fitted `grid.canvas` carries the resulting drawable area. Axis queries expose major, minor, and halfway lines and
points.

## Rulers and tiles

`Sevgi::Sundries::Ruler` divides a span while respecting margins. `Sevgi::Sundries::Tile` arranges geometry-backed
objects into rows and columns and exposes cell, row, column, and overall boxes. Use the DSL `Tile`, `TileX`, and `TileY`
when repeated SVG `<use>` elements are the desired output.

## Export {#export}

SVG output needs no native graphics libraries. PDF and PNG export are optional:

```ruby
drawing = SVG(width: 40, height: 40) do
  circle cx: 20, cy: 20, r: 16, fill: "tomato"
end

drawing.PNG "badge.png", dpi: 144
drawing.PDF "badge.pdf"
```

The native path uses Cairo, librsvg, and HexaPDF integrations. Missing optional dependencies raise a Sevgi component
error rather than changing ordinary SVG rendering.
