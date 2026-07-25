# Layout Routing

Choose by the value the caller needs after the operation, not merely by the visible pattern.

## Repetition

| Need | Use | Result |
| --- | --- | --- |
| Repeat one SVG subtree in the rendered document | `defs`/`use`, or DSL `Tile`, `TileX`, `TileY` | SVG references with generated positions |
| Copy and independently edit an existing subtree | `Duplicate`, `DuplicateX`, `DuplicateY` | Independent SVG element trees |
| Inspect repeated cells or row/column bounds in Ruby | `Sevgi::Sundries::Tile` | Geometry values and boxes, no SVG elements |

## Intervals and Grids

| Need | Use |
| --- | --- |
| Fit whole major/minor intervals into a span and inspect their distances | `Sevgi::Sundries::Ruler` |
| Require an even major-interval count | `Sevgi::Sundries::RulerEven` |
| Combine two fitted rulers and obtain lines, points, cells, or a fitted canvas | `SVG.Grid` or `Sevgi::Sundries::Grid` |

`Ruler` is a Ruby value, not a drawing word. `Grid` is also a Ruby layout model; `Draw` materializes its geometry as SVG
when lines are required. In a Grid, `grid.x` returns horizontal lines and `grid.y` vertical lines—the names describe
line direction.

## Alignment

| Need | Use |
| --- | --- |
| Center known inner and outer boxes with an SVG translation | element `Align` with `:center` |
| Align Geometry at center or an edge and return the value or offset | `Sevgi::Geometry::Operation.align` or `Sevgi::Geometry::Operation.alignment` |
| Align rendered text or other renderer-owned content | SVG anchoring, baseline, layout, or transform semantics |

Geometry alignment accepts `:center`, `:left`, `:right`, `:top`, and `:bottom`; the element DSL's narrower `Align`
contract accepts only `:center`. Do not calculate font or painted-content bounds merely to feed either API; use them
when the program already owns meaningful box geometry.

## Drawing and Hatching

| Need | Use |
| --- | --- |
| A visual repeated fill whose individual strokes are irrelevant | SVG `pattern`; let the renderer repeat and clip it |
| Explicit finite hatch segments that must remain separate geometry/SVG paths | Geometry sweep or `Hatch` |
| Existing Geometry values rendered as SVG elements | `Draw` |

`Hatch` computes finite segments and emits each as a separate SVG path. Use it for editable, inspectable, plotter-like,
or otherwise explicit line geometry—not merely because a region should look striped. `Draw` and `Hatch` are included by
`:inkscape`; add the Hatch mixture to another profile only when that profile deliberately owns the capability. For a
scoped extension, subclass `SVG::Document::Base`, then call `SVG.Mixin :Hatch, profile`; targeting `Base` itself changes
every descendant profile process-wide.

Read the [Sundries guide](https://sevgi.roktas.dev/sundries/) for Ruler, Grid, and both Tile models; read
[Geometry sweeps and hatching](https://sevgi.roktas.dev/geometry/#sweeps) for explicit hatch lines; use the
[DSL Catalog](https://sevgi.roktas.dev/dsl/) for exact drawing words. Exact Ruby contracts live in
[`sevgi-sundries`](https://www.rubydoc.info/gems/sevgi-sundries) and
[`sevgi-graphics`](https://www.rubydoc.info/gems/sevgi-graphics).
