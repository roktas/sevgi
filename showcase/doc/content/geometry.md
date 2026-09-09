+++
title = "Geometry"
weight = 12
[extra]
group = "Guides"
+++

Geometry supplies a small set of immutable values for calculations the SVG renderer cannot do for you. It uses SVG
screen coordinates: positive x goes right, positive y goes down, and positive angles turn clockwise.

Think of the component as the calculation layer beneath a drawing. Build values, transform or intersect them, then pass
the results to `Draw`, `Hatch`, `Align`, or your own Ruby code. No geometry constructor adds an SVG element by itself.

## Points and lines {{ "{#points-and-lines}" }}

```ruby
point = Sevgi::Geometry::Point[3, 4]
line = Sevgi::Geometry::Line.([0, 0], point)

line.length                                     # => 5.0
Sevgi::Geometry::Point.midpoint([0, 0], point) # => Point[1.5, 2.0]
point.translate(2, 1)                           # => Point[5.0, 5.0]
```

Points and lined shapes return new values from `translate`, `rotate`, `scale`, `skew`, and `reflect`. The original value
does not change. A `Segment` is an unplaced length and direction. A `Line` places that segment between finite endpoints:

```ruby
segment = Sevgi::Geometry::Segment[5, 30]
ending = segment.ending([2, 3])
line = segment.line([2, 3])
```

A directed open path exposes its endpoints and can reverse its traversal:

```ruby
path = Sevgi::Geometry::Polyline.([0, 0], [8, 0], [8, 5])

path.starting # => Point[0.0, 0.0]
path.ending   # => Point[8.0, 5.0]
path.closed? # => false
path.reverse.points == path.points.reverse # => true
```

## Shapes

`Rect`, `Triangle`, `Parallelogram`, `Polyline`, and `Polygon` provide boxes, points, edges, and affine operations. Pick
the constructor that matches your input. Brackets take lengths and segments. `.()` takes points:

```ruby
box = Sevgi::Geometry::Rect[40, 24, position: [6, 8]]
same_box = Sevgi::Geometry::Rect.([6, 8], [46, 32])

polar_line = Sevgi::Geometry::Line[10, 30, position: [2, 3]]
point_line = Sevgi::Geometry::Line.([2, 3], [12, 8])

open_path = Sevgi::Geometry::Polyline.([0, 0], [8, 0], [8, 5])
closed_path = Sevgi::Geometry::Polygon.([0, 0], [8, 0], [8, 5], [0, 5])
triangle = Sevgi::Geometry::Triangle.([0, 20], [10, 0], [20, 20])

closed_path.closed? # => true
open_path.closed?   # => false
```

The English constructors such as `Rect.from_size`, `Rect.from_corners`, `Line.from_length_angle`, and
`Line.from_points` are aliases for the same two input families. Use them when the call site benefits from saying which
representation it has.

Parallelogram segment names describe geometric roles, not screen axes. `base` runs from A to B. `side` runs from A to
D. Both begin at `position`. The constrained constructors derive the missing segment while preserving the requested
bounding dimension:

```ruby
shape = Sevgi::Geometry::Parallelogram.new_by_height(
  base: [12, 15],
  constraint: [8, 105],
  position: [2, 3]
)

shape.AB.angle # => 15.0
shape.DA.angle # => 105.0
shape.box.height # => 8.0
```

Every lined shape exposes the same path as `points`, `segments`, and `lines`. `vertices` gives the geometric vertices in
path order. Closed shapes repeat the first vertex at the end of `points`, but `vertices` omits that closing repetition:

```ruby
box = Sevgi::Geometry::Rect[40, 24]

box.vertices.size == 4                         # => true
box.points.size == 5                           # => true
box.vertices == [box.A, box.B, box.C, box.D]  # => true
box.points == [box.A, box.B, box.C, box.D, box.A] # => true
```

Open shapes do not repeat an endpoint, so `vertices` and `points` contain the same points. Use `closed?` when behavior
depends on whether the boundary returns to its start. Closure describes the path topology, not whether the shape has
nonzero area.

Closed shapes distinguish interior, boundary, and exterior points. Open paths have no filled interior:

```ruby
box = Sevgi::Geometry::Rect[40, 24, position: [6, 8]]
open_path = Sevgi::Geometry::Polyline.([0, 0], [8, 0], [8, 5])

box.inside?([20, 20])     # => true
box.on?([6, 20])          # => true
box.outside?([50, 20])    # => true
open_path.inside?([4, 2]) # => false
```

A rectangle exposes its geometric center directly. For any other element, use the center of its bounding box when that
is the intended meaning. `Operation.box` combines the existing boxes of several elements into their smallest common
axis-aligned rectangle:

```ruby
box = Sevgi::Geometry::Rect[40, 24, position: [6, 8]]
open_path = Sevgi::Geometry::Polyline.([0, 0], [8, 0], [8, 5])

box.center           # => Point[26.0, 20.0]
open_path.box.center # => Point[4.0, 2.5]

combined = Sevgi::Geometry::Operation.box(box, open_path)
combined.position # => Point[0.0, 0.0]
combined.width    # => 46.0
combined.height   # => 32.0
```

Zero-size elements still contribute their position to `Operation.box`; they are not discarded merely because
`ignorable?` is true.

## Relations {{ "{#relations}" }}

`Point.collinear?` tests a set of at least three point-like values with the same precision rules as other Geometry
comparisons. `Polygon` adds boundary and shape classification predicates:

```ruby
Sevgi::Geometry::Point.collinear?([0, 0], [2, 2], [4, 4]) # => true

convex = Sevgi::Geometry::Polygon.([0, 0], [4, 0], [4, 4], [0, 4])
concave = Sevgi::Geometry::Polygon.([0, 0], [4, 0], [2, 2], [4, 4], [0, 4])
crossed = Sevgi::Geometry::Polygon.([0, 0], [4, 4], [0, 4], [4, 0])

convex.simple?   # => true
convex.convex?   # => true
concave.concave? # => true
crossed.simple?  # => false
crossed.convex?  # => false
crossed.concave? # => false
```

A simple polygon has no self-intersections, non-adjacent boundary touches, or overlapping edges. Redundant collinear
vertices along a straight edge do not prevent convexity. A self-intersecting or fully degenerate polygon is neither
convex nor concave. Pass `precision:` to these predicates when near-collinear coordinates should use an explicit decimal
precision.

## Arcs and ellipses {{ "{#arcs-and-ellipses}" }}

`Ellipse` stores a center, two positive radii, and an axis rotation. `Arc` selects a finite, directed part of that ellipse:

```ruby
ellipse = Sevgi::Geometry::Ellipse[40, 20, position: [50, 30], rotation: 15]
arc = ellipse.arc starting_angle: 180, extent: 120

arc.starting
arc.ending
arc.box
arc.length
arc.reverse
```

The parameter angle belongs to the ellipse's local axes. It is not the polar angle from the center when the radii differ.
Positive `extent` turns clockwise. Its absolute value must be less than 360 degrees. Zero extent contains only its starting point and draws nothing.

`Circle` is an ellipse with equal radii. Unequal scaling returns an `Ellipse`. Transformations also preserve a finite arc's endpoints and traversal:

```ruby
circle = Sevgi::Geometry::Circle[20, position: [30, 30]]
ellipse = circle.scale 2, 1
arc = circle.arc starting_angle: 180, extent: 180
stretched = arc.skew_x 20
```

`inside?` includes the boundary of an ellipse or circle. An arc has no filled interior, so its `inside?` equals `on?`.
`intersection` filters the complete ellipse equation to the finite arc:

```ruby
arc = Sevgi::Geometry::Arc[20, starting_angle: 180, extent: 180]
points = arc.intersection Sevgi::Geometry::Equation.vertical(0)
points.map(&:deconstruct) # => [[0.0, -20.0]]
```

Coordinate precision controls membership and rounded intersection points. It does not change stored geometry, bounds, or length accuracy.
`approx` rounds canonical fields and returns a new value. It raises an error if a radius becomes zero or an extent reaches a full turn.

For drawing alone, `ArcTo` and `ArcBy` use SVG endpoint and radius rules directly. Their `large` and `sweep` flags select the SVG arc.
They do not require Geometry. The [Protractor example](/examples/) uses `ArcTo` and SVG rotation to place its marks.

## Alignment {{ "{#alignment}" }}

Alignment calculates the translation between an inner and outer box. The DSL `Align` helper applies that translation
as an SVG transform. Library code can request either the offset or a translated geometry value directly:

```ruby
inner = Sevgi::Geometry::Rect[8, 4]
outer = Sevgi::Geometry::Rect[40, 20, position: [5, 5]]

outer.center # => Point[25.0, 15.0]
offset = Sevgi::Geometry::Operation.alignment(inner, outer, :center)
centered = Sevgi::Geometry::Operation.align(inner, outer, :center)
```

`:center` adjusts both coordinates. `:left`, `:right`, `:top`, and `:bottom` adjust only the named axis. Edge alignment
therefore keeps the existing position on the other axis.

The drawing equivalent is:

```ruby
inner = Sevgi::Geometry::Rect[8, 4]
outer = Sevgi::Geometry::Rect[40, 20, position: [5, 5]]

SVG :minimal do
  shape = rect width: 8, height: 4
  shape.Align :center, inner:, outer:
end.Render
```

## Drawing {{ "{#drawing}" }}

In an Inkscape document, `Draw` converts geometry into suitable SVG elements:

```ruby
region = Sevgi::Geometry::Rect[48, 18, position: [6, 6]]

SVG :inkscape do
  trim = Sevgi::Geometry::Rect[80, 50, position: [5, 5]]
  Draw trim.lines, class: %w[guide trim], stroke: "tomato"
end.Render
```

## Sweeps and hatching {{ "{#sweeps}" }}

Sweeps intersect parallel lines with a closed geometry shape. `angle` is the direction of the returned lines. `step` is
their perpendicular spacing. `sweep` can return an empty Array. `sweep!`, which `Hatch` uses, requires at least one
span. Open paths have no interior and therefore produce no sweep spans:

```ruby
region = Sevgi::Geometry::Rect[48, 18, position: [6, 6]]
lines = Sevgi::Geometry::Operation.sweep(region, initial: region.position, angle: 30, step: 3)
```

The same geometry can be sent to a document. `Hatch` uses `region.position` as its initial line unless `initial:` is
given:

```ruby
region = Sevgi::Geometry::Rect[48, 18, position: [6, 6]]

SVG :inkscape do
  Hatch region, angle: 30, step: 3, class: %w[guide no-print], stroke: "black"
end.Render
```

`Hatch` materializes each finite segment as a separate SVG path. Use it when those segments must remain editable,
inspectable, or available as explicit geometry. If only the rendered striped fill matters, prefer an SVG
[`pattern`](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/pattern) and let the renderer repeat and
clip it.

Closed ellipses and circles also support sweeps. An open arc produces no interior spans.
