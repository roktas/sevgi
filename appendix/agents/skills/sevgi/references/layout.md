# Layout Routing

Choose by the value the caller needs after the operation, not merely by the visible pattern.

## Repetition

| Need | Use | Result |
| --- | --- | --- |
| Repeat one SVG subtree in the rendered document | `defs`/`use`, or DSL `Tile`, `TileX`, `TileY` | SVG references with generated positions |
| Copy and independently edit an existing subtree | `Duplicate`, `DuplicateX`, `DuplicateY` | Independent SVG element trees |
| Inspect repeated cells or row/column bounds in Ruby | `Sevgi::Sundries::Tile` | Geometry values and boxes, no SVG elements |

The repetition APIs have different block contracts:

| API channel | Runs for | Use |
| --- | --- | --- |
| `Tile`, `TileX`, `TileY` block | One template under `defs` | Draw the shared subtree, not each cell |
| Tile `proc:` | Each generated `use` element | Mutate that element through the callback argument. Row and column indices are zero-based |
| `Duplicate`, `DuplicateX`, `DuplicateY` block | Every copied element | Customize the yielded element, not a new drawing context |

`Duplicate` moves visible `id` attributes to non-rendering `-id` metadata before customization.
An existing `-id` takes precedence. Assign replacement IDs explicitly when needed.
The copied subtree attaches to its target parent after customization. Do not depend on that attachment during the callback.
Use the exact callback keywords from the selected method's YARD contract. The Tile variants differ.

## Intervals and Grids

| Need | Use |
| --- | --- |
| Fit whole major/minor intervals into a span and inspect their distances | script `Ruler`, library `SVG.Ruler`, or component `Sevgi::Sundries::Ruler` |
| Require an even major-interval count | `Sevgi::Sundries::RulerEven` |
| Combine two fitted rulers and obtain lines, points, cells, or a fitted canvas | `SVG.Grid` or `Sevgi::Sundries::Grid` |

`Ruler` constructs a Ruby layout value without drawing SVG elements. `Grid` also returns a layout model.
`Draw` materializes its geometry as SVG when lines are required. In a Grid, `grid.x` returns horizontal lines and
`grid.y` vertical lines—the names describe line direction.

## Alignment

| Need | Use |
| --- | --- |
| Center known inner and outer boxes with an SVG translation | element `Align` with `:center` |
| Align Geometry at center or an edge and return the value or offset | `Sevgi::Geometry::Operation.align` or `Sevgi::Geometry::Operation.alignment` |
| Align rendered text or other renderer-owned content | SVG anchoring, baseline, layout, or transform semantics |

Geometry alignment accepts `:center`, `:left`, `:right`, `:top`, and `:bottom`. The element DSL's narrower `Align`
contract accepts only `:center`. Do not calculate font or painted-content bounds only to feed either API. Use these
APIs when the program already owns meaningful box geometry.

`Align` includes both box origins. Width-and-height-only objects have origin `(0, 0)`.
An object with `position` must supply finite numeric `x` and `y` coordinates:

```ruby
inner = Sevgi::Geometry::Rect[8, 4, position: [2, 3]]
outer = Sevgi::Geometry::Rect[40, 20, position: [5, 5]]
drawing = SVG width: 50, height: 30 do
  shape = rect x: 2, y: 3, width: 8, height: 4
  shape.Align :center, inner:, outer:
end
drawing.Render # The rectangle receives translate(19 10).
```

## Curved Geometry

For an SVG path, use `ArcTo` or `ArcBy`. The renderer resolves their endpoint, radius, `large`, and `sweep` rules.
Use `Geometry::Circle`, `Geometry::Ellipse`, or `Geometry::Arc` when Ruby needs intersections, endpoints, or bounds.
An arc has a finite extent and no filled interior. Positive angles run clockwise in screen coordinates, where y
increases downward. See [Geometry](https://sevgi.roktas.dev/geometry/#arcs-and-ellipses) and the installed Geometry YARD.

## Drawing and Hatching

| Need | Use |
| --- | --- |
| A visual repeated fill whose individual strokes are irrelevant | SVG `pattern` that the renderer repeats and clips |
| Explicit finite hatch segments that must remain separate geometry/SVG paths | Geometry sweep or `Hatch` |
| Existing Geometry values rendered as SVG elements | `Draw` |

`Hatch` computes finite segments and emits each as a separate SVG path. Use it for editable, inspectable, plotter-like,
or otherwise explicit line geometry. Do not use it only because a region needs stripes. `Draw` and `Hatch` are included
by `:inkscape`. Add the Hatch mixture to another profile only when that profile owns the capability. For a scoped
extension, subclass `SVG::Document::Base`, then call `SVG.Mixin :Hatch, profile`. Targeting `Base` itself changes
every descendant profile process-wide.

Read the [Layout guide](https://sevgi.roktas.dev/layout/) for Ruler, Grid, and both Tile models. Read
[Geometry sweeps and hatching](https://sevgi.roktas.dev/geometry/#sweeps) for explicit hatch lines. Use the
[DSL Catalog](https://sevgi.roktas.dev/dsl/) for exact drawing words. Exact Ruby contracts live in
[`sevgi-sundries`](https://www.rubydoc.info/gems/sevgi-sundries) and
[`sevgi-graphics`](https://www.rubydoc.info/gems/sevgi-graphics).
