+++
title = "Sundries"
weight = 13
[extra]
group = "Toolkit"
+++

Sundries supplies the layout bridge between dimensions and drawings. A ruler fits repeated distances into one span, a
grid combines two rulers, and a tile repeats one geometry value. They are regular Ruby objects, not another drawing DSL,
so applications can inspect and test a layout before creating any SVG elements. Export is the separate output-oriented
part of the component.

## Choose a layout model {#choose-a-layout-model}

Choose by the value the rest of the program needs, not only by the visible repetition:

| Need | Use | Result |
| --- | --- | --- |
| Repeat one SVG template in the document | DSL `Tile`, `TileX`, or `TileY` | `<defs>` plus positioned `<use>` elements |
| Copy independently editable SVG subtrees | `Duplicate`, `DuplicateX`, or `DuplicateY` | separate element trees |
| Inspect repeated cells and their bounds in Ruby | `Sevgi::Sundries::Tile` | geometry values without SVG output |
| Fit major and minor intervals into one span | `Ruler` or `RulerEven` | inspectable distances and margins |
| Combine two fitted rulers | `SVG.Grid` or `Sevgi::Sundries::Grid` | lines, points, cells, and a fitted canvas |

## Rulers {#rulers}

`Ruler` fits whole major intervals inside a span. `unit` is the smallest step; `multiple` says how many units form one
major interval. Requested margins are minimums. Any distance left after fitting whole major intervals is split between
them while preserving an asymmetric start/end difference:

```ruby
ruler = Sevgi::Sundries::Ruler.new(
  brut: 103,
  unit: 1,
  multiple: 10,
  margins: [5]
)

ruler.n       # => 9 major intervals
ruler.ds      # major distances
ruler.hs      # halfway distances
ruler.ms      # minor distances
ruler.margins # => [6.5, 6.5]
ruler.d       # => 90.0 fitted distance, excluding margins
ruler.waste   # => 13.0 margins plus unfitted remainder
```

Use `RulerEven` when the number of major intervals must be even. The compact readers `u`, `n`, and `d` mean interval
length, count, and fitted distance. `su`, `sn`, and `sd` describe the source subinterval.

## Grid {#grid}

`Grid` combines one horizontal and one vertical ruler. In library mode, `SVG.Grid` builds both rulers from a canvas and
preserves that canvas's size, unit, and name while replacing its margins with the fitted values:

```ruby
canvas = SVG.Canvas width: 80, height: 50, margins: [5]
grid = SVG.Grid canvas, unit: 1, multiple: 10

drawing = SVG :inkscape, grid.canvas do
  Draw grid.x.major.lines, class: %w[guide horizontal], stroke: "silver"
  Draw grid.y.major.lines, class: %w[guide vertical], stroke: "silver"
end

drawing.Render
```

Axis names describe line direction: `grid.x` produces horizontal lines, and `grid.y` produces vertical lines. The
positions of horizontal lines therefore come from the vertical ruler, and vice versa. Each major, minor, or halfway
query has three representations:

| Reader | Value | Typical use |
| --- | --- | --- |
| `lines` | geometry `Line` objects | pass a complete set to `Draw` |
| `points` | pairs of geometry `Point` objects | place marks at both endpoints |
| `xys` | pairs of plain coordinate Arrays | feed data-only consumers |

```ruby
canvas = SVG.Canvas width: 80, height: 50, margins: [5]
grid = SVG.Grid canvas, unit: 1, multiple: 10

grid.x.major.lines  # geometry Line objects, suitable for Draw
grid.x.halve.points # endpoint Point pairs
grid.y.minor.xys    # plain coordinate pairs
```

`Grid` also inherits tile accessors. `grid.rowbox(i)` and `grid.colbox(i)` are useful when a hatch or another operation
should be constrained to one row or column. This is the pattern used by guide-sheet consumers:

```ruby
canvas = SVG.Canvas width: 80, height: 50, margins: [5]
grid = SVG.Grid canvas, unit: 1, multiple: 10

SVG :inkscape, grid.canvas do
  Hatch grid.rowbox(0), angle: -30, step: grid.x.su, stroke: "silver"
end.Render
```

## Tiles {#tiles}

`Tile` arranges copies of one geometry value into rows and columns. The source element's bounding box sets the cell
pitch, and indexing is row-first:

```ruby
cell = Sevgi::Geometry::Rect[8, 4]
tile = Sevgi::Sundries::Tile.new(cell, position: [10, 20], nx: 3, ny: 2)

tile[1][2].position # row 1, column 2
tile.rowbox(1)      # bounds of the second row
tile.colbox(2)      # bounds of the third column
tile.box            # bounds of the complete layout
```

Use this Ruby object when later calculations need the cells or their bounds. Use the DSL words `Tile`, `TileX`, or
`TileY` instead when the output should define one SVG template and repeat it with `<use>` elements.

## Export {#export}

SVG output needs no native graphics libraries. PDF and PNG export are optional:

```ruby
canvas = SVG.Canvas width: 40, height: 40, unit: :px
drawing = SVG :minimal, canvas do
  circle cx: 20, cy: 20, r: 16, fill: "tomato"
end

drawing.PNG "badge.png", dpi: 144
drawing.PDF "badge.pdf"
```

Applications that keep output policy outside the document can call the component directly. The file suffix selects
the format when `format:` is omitted, and the return value is the expanded output path:

```ruby
canvas = SVG.Canvas width: 40, height: 40, unit: :px
drawing = SVG(:minimal, canvas) { circle cx: 20, cy: 20, r: 16, fill: "tomato" }
Sevgi::Sundries::Export.call(drawing.Render, "badge.png", width: 320)
```

Export `width` and `height` control output dimensions; they do not replace the SVG canvas or repair its `viewBox` or
visible geometry. Define those relationships in the drawing before export. Use `css:` only for deliberate export-only
styling.

PDF and PNG output uses Cairo, librsvg, and HexaPDF. If one is missing, Sevgi raises a component error. Ordinary SVG
rendering still works without them.
