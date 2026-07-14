+++
title = "Geometry"
weight = 12
[extra]
group = "Toolkit"
+++

Geometry is the small, immutable model Sevgi uses when the renderer cannot do the calculation for you. It follows SVG
screen coordinates: positive x goes right, positive y goes down, and positive angles turn clockwise.

## Points and lines {#points-and-lines}

```ruby
point = Sevgi::Geometry::Point[3, 4]
line = Sevgi::Geometry::Line.([0, 0], point)

line.length             # => 5.0
point.translate(2, 1)   # => Point[5.0, 5.0]
```

Points and lined shapes return new values from `translate`, `rotate`, `scale`, `skew`, and `reflect`; the original value
does not change.

## Shapes

`Rect`, `Triangle`, `Parallelogram`, `Polyline`, and `Polygon` provide boxes, points, edges, and affine operations. Use
the shortest constructor that preserves the idea:

```ruby
box = Sevgi::Geometry::Rect[40, 24, position: [6, 8]]
triangle = Sevgi::Geometry::Triangle.([0, 20], [10, 0], [20, 20])
```

## Alignment {#alignment}

Alignment calculates the translation between an inner and outer box; the DSL `Align` helper applies it as an SVG
transform:

```ruby
inner = Sevgi::Geometry::Rect[8, 4]
outer = Sevgi::Geometry::Rect[40, 20]

SVG(:minimal) { rect(width: 8, height: 4).Align :center, inner:, outer: }.Render
```

## Drawing {#drawing}

In an Inkscape document, `Draw` converts geometry into suitable SVG elements:

```ruby
SVG(:inkscape) do
  line = Sevgi::Geometry::Line.([2, 2], [18, 10])
  Draw line, stroke: "tomato"
end.Render
```

## Sweeps and hatching {#sweeps}

Sweeps intersect parallel lines with a closed geometry shape. `Hatch` is the drawing-level convenience:

```ruby
SVG(:inkscape) do
  Hatch Sevgi::Geometry::Rect[24, 16], angle: 30, step: 3, stroke: "black"
end.Render
```

Geometry intentionally stays focused. Unfinished arc and curve preparation APIs are not part of the supported surface.
