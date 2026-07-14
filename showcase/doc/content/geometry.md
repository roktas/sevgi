+++
title = "Geometry"
weight = 12
[extra]
group = "Toolkit"
+++

Geometry supplies a small set of immutable values for calculations the SVG renderer cannot do for you. It uses SVG
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

`Rect`, `Triangle`, `Parallelogram`, `Polyline`, and `Polygon` provide boxes, points, edges, and affine operations. Pick
the constructor that makes the input easiest to read:

```ruby
box = Sevgi::Geometry::Rect[40, 24, position: [6, 8]]
triangle = Sevgi::Geometry::Triangle.([0, 20], [10, 0], [20, 20])
```

## Alignment {#alignment}

Alignment calculates the translation between an inner and outer box. The DSL `Align` helper applies that translation
as an SVG transform:

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

Sweeps intersect parallel lines with a closed geometry shape. `Hatch` draws the result:

```ruby
SVG(:inkscape) do
  Hatch Sevgi::Geometry::Rect[24, 16], angle: 30, step: 3, stroke: "black"
end.Render
```

Arc and curve preparation is still incomplete, so those APIs are not supported yet.
