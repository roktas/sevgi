+++
title = "Geometry"
weight = 12
[extra]
group = "Toolkit"
+++

Geometry supplies a small set of immutable values for calculations the SVG renderer cannot do for you. It uses SVG
screen coordinates: positive x goes right, positive y goes down, and positive angles turn clockwise.

Think of the component as the calculation layer beneath a drawing: build values, transform or intersect them, then pass
the resulting lines or shapes to `Draw`, `Hatch`, `Align`, or your own Ruby code. No geometry constructor adds an SVG
element by itself.

## Points and lines {#points-and-lines}

```ruby
point = Sevgi::Geometry::Point[3, 4]
line = Sevgi::Geometry::Line.([0, 0], point)

line.length             # => 5.0
point.translate(2, 1)   # => Point[5.0, 5.0]
```

Points and lined shapes return new values from `translate`, `rotate`, `scale`, `skew`, and `reflect`; the original value
does not change. A `Segment` is an unplaced length and direction; a `Line` places that segment between finite endpoints:

```ruby
segment = Sevgi::Geometry::Segment[5, 30]
ending = segment.ending([2, 3])
line = segment.line([2, 3])
```

## Shapes

`Rect`, `Triangle`, `Parallelogram`, `Polyline`, and `Polygon` provide boxes, points, edges, and affine operations. Pick
the constructor that matches the information you already have. Brackets take lengths and segments; `.()` takes points:

```ruby
box = Sevgi::Geometry::Rect[40, 24, position: [6, 8]]
same_box = Sevgi::Geometry::Rect.([6, 8], [46, 32])

polar_line = Sevgi::Geometry::Line[10, 30, position: [2, 3]]
point_line = Sevgi::Geometry::Line.([2, 3], [12, 8])

open_path = Sevgi::Geometry::Polyline.([0, 0], [8, 0], [8, 5])
closed_path = Sevgi::Geometry::Polygon.([0, 0], [8, 0], [8, 5], [0, 5])
triangle = Sevgi::Geometry::Triangle.([0, 20], [10, 0], [20, 20])
```

The English constructors such as `Rect.from_size`, `Rect.from_corners`, `Line.from_length_angle`, and
`Line.from_points` are aliases for the same two input families. Use them when the call site benefits from saying which
representation it has.

Every lined shape exposes the same path in three forms: `points` for vertex work, `segments` for reusable polar
displacements, and `lines` for finite positioned edges. Closed shapes repeat the first point at the end of `points`, so
a rectangle has five path points but four segments and four lines.

Closed shapes distinguish interior, boundary, and exterior points. Open paths have no filled interior:

```ruby
box = Sevgi::Geometry::Rect[40, 24, position: [6, 8]]
open_path = Sevgi::Geometry::Polyline.([0, 0], [8, 0], [8, 5])

box.inside?([20, 20])    # => true
box.on?([6, 20])         # => true
box.outside?([50, 20])   # => true
open_path.inside?([4, 2]) # => false
```

## Alignment {#alignment}

Alignment calculates the translation between an inner and outer box. The DSL `Align` helper applies that translation
as an SVG transform. Library code can request either the offset or a translated geometry value directly:

```ruby
inner = Sevgi::Geometry::Rect[8, 4]
outer = Sevgi::Geometry::Rect[40, 20, position: [5, 5]]

offset = Sevgi::Geometry::Operation.alignment(inner, outer, :center)
centered = Sevgi::Geometry::Operation.align(inner, outer, :center)
```

`:center` adjusts both coordinates. `:left`, `:right`, `:top`, and `:bottom` adjust only the named axis; this makes it
possible to align one edge without losing a position already chosen on the other axis.

The drawing equivalent is:

```ruby
inner = Sevgi::Geometry::Rect[8, 4]
outer = Sevgi::Geometry::Rect[40, 20, position: [5, 5]]

SVG :minimal do
  shape = rect width: 8, height: 4
  shape.Align :center, inner:, outer:
end.Render
```

## Drawing {#drawing}

In an Inkscape document, `Draw` converts geometry into suitable SVG elements:

```ruby
region = Sevgi::Geometry::Rect[48, 18, position: [6, 6]]

SVG :inkscape do
  trim = Sevgi::Geometry::Rect[80, 50, position: [5, 5]]
  Draw trim.lines, class: %w[guide trim], stroke: "tomato"
end.Render
```

## Sweeps and hatching {#sweeps}

Sweeps intersect parallel lines with a closed geometry shape. `angle` is the direction of the returned lines, while
`step` is the perpendicular spacing between them. `sweep` may return an empty Array; `sweep!`, used by `Hatch`, requires
at least one span. Open paths have no interior and therefore produce no sweep spans:

```ruby
region = Sevgi::Geometry::Rect[48, 18, position: [6, 6]]
lines = Sevgi::Geometry::Operation.sweep(region, initial: region.position, angle: 30, step: 3)
```

The same geometry can be sent to a document; `Hatch` uses `region.position` as its initial line unless `initial:` is
given:

```ruby
region = Sevgi::Geometry::Rect[48, 18, position: [6, 6]]

SVG :inkscape do
  Hatch region, angle: 30, step: 3, class: %w[guide no-print], stroke: "black"
end.Render
```

Arc and curve preparation is still incomplete, so those APIs are not supported yet.
