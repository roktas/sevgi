# Drawing Discipline

## Renderer First

Treat SVG as the rendering model, not merely as an output format. The governing question is not whether Ruby *can*
calculate a value, but which layer has the knowledge and responsibility to determine it.

Use this ownership boundary:

| Owner | Test | Action |
| --- | --- | --- |
| SVG renderer | SVG can state the intent and the final result depends on rendering context | Encode the intent with SVG elements, attributes, CSS, or transforms |
| Sevgi | Sevgi already names the SVG operation or supplies the required layout abstraction | Use the DSL or helper instead of rebuilding it |
| Program | The value must exist before rendering and SVG neither derives nor exposes it | Compute it with ordinary Ruby or `Sevgi::Geometry` |

Before computing, first ask whether SVG can state the desired relationship rather than its current numeric result. If
it can, keep that relationship declarative. Then check whether Sevgi already wraps it. Compute only when the program
needs geometry or data that the renderer cannot provide as part of the supported workflow.

Geometry is appropriate for constructed points and lines, intersections, bounds consumed by later algorithms, sweeps,
and hatching. It is not a parallel rendering engine.

## Example: Preserve the Ownership Boundary

The Showcase Ruler illustrates the general rule; it does not introduce a text-specific recipe. The desired relationship
is “center each label on this tick,” while the rendered width of a label depends on font metrics known by the SVG
renderer.

Computing a guessed width in Ruby takes ownership away from the renderer:

```ruby
(10..(WIDTH - 10)).step(10).each_with_index do |x, i|
  label = (i + 1).to_s
  estimated_width = label.length * 4 * 0.6
  text label, x: x - (estimated_width / 2), y: length + 5.5, class: "labels"
end
```

Instead, keep the tick coordinate and express the relationship in SVG:

```ruby
(10..(WIDTH - 10)).step(10).each_with_index do |x, i|
  label = (i + 1).to_s
  text label, x:, y: length + 5.5, "text-anchor": "middle", class: "labels"
end
```

The broader lesson is to encode the stable relationship and leave context-dependent rendering values to the renderer.
Apply that reasoning before introducing measured compensations or Geometry objects solely to imitate rendering.

## Root-Cause Review

When a drawing looks wrong, inspect these contracts separately:

1. **Source geometry:** coordinates, intervals, repetition counts, and intended visible bounds.
2. **Layout framing:** content bounds, margins, alignment, and repetition policy.
3. **Viewport:** `width`, `height`, `viewBox`, and `preserveAspectRatio`.
4. **Painting:** stroke width, line caps/joins, fill, opacity, filters, and CSS cascade.
5. **Transforms:** order, origin, inherited transforms, and duplicated translations.
6. **Environment:** font availability, renderer support, output size, and theme-specific styles.

Fix the first contract that is false. Do not make a frame larger to hide unequal content, add whitespace to simulate
alignment, clip an overflow caused by wrong geometry, or use a special-case offset that only matches one label or
viewport.

Verify every rendering context the artifact claims to support. For browser assets this may include representative
desktop/mobile widths and light/dark themes; for print output it may include page sizes and an independent PDF renderer.
Equal SVG dimensions or DOM boxes do not prove equal visible size.

## Layout Changes

Treat the viewport, visible drawing bounds, and visual density as separate contracts. When changing a canvas, grid, or
repeated layout, reconsider interval counts, hatch spacing, margins, and stroke weights together instead of scaling one
number mechanically.

For a drawing parameterized across sizes or profiles, check representative extremes and nearby values that share the
same layout rule. Judge actual whitespace, visual balance, row and column counts, clipping, and perceived density.
Rounding or repetition changes can fix one variant while regressing another. Do not use an offset to hide a wrong
geometry, interval, or viewport model.
