+++
title = "Sundries"
weight = 13
[extra]
group = "Toolkit"
+++

Sundries holds the odds and ends shared by several components, mainly layout objects and export tools. They are regular
Ruby objects, not another drawing DSL.

## Grid {#grid}

`Grid` fits major and minor ruler intervals into a canvas. It is available as a top-level constructor in scripts:

```ruby
canvas = SVG.canvas width: 80, height: 50, margins: 5
grid = Grid canvas, unit: 1, multiple: 10

SVG :inkscape, grid.canvas do
  Draw grid.x.major.lines, class: %w[guide horizontal], stroke: "silver"
  Draw grid.y.major.lines, class: %w[guide vertical], stroke: "silver"
end.Render
```

After fitting, `grid.canvas` contains the drawable area. Each axis provides its major, minor, and halfway lines and
points.

## Rulers and tiles

`Sevgi::Sundries::Ruler` divides a span without crossing its margins. `Sevgi::Sundries::Tile` arranges geometry-backed
objects into rows and columns, with boxes for each cell and for the complete layout. Use the DSL words `Tile`, `TileX`,
or `TileY` instead when you want repeated SVG `<use>` elements.

## Export {#export}

SVG output needs no native graphics libraries. PDF and PNG export are optional:

```ruby
drawing = SVG width: 40, height: 40 do
  circle cx: 20, cy: 20, r: 16, fill: "tomato"
end

drawing.PNG "badge.png", dpi: 144
drawing.PDF "badge.pdf"
```

PDF and PNG output uses Cairo, librsvg, and HexaPDF. If one is missing, Sevgi raises a component error. Ordinary SVG
rendering still works without them.
