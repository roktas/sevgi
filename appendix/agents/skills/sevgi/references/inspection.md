# Inspection

Measure rendered output only when the acceptance criterion requires evidence about size, alignment, clipping, density,
or a visual regression. Measurement is diagnostic evidence, not permission to copy observed coordinates back into the
DSL as compensating offsets. Use the evidence to locate the faulty source, viewport, layout, paint, transform, or
environment contract, then fix that owner.

## Choose the Evidence

State the question before selecting a tool:

| Question | Evidence | Space |
| --- | --- | --- |
| Is the declared coordinate model correct? | `viewBox`, viewport dimensions, `preserveAspectRatio` | SVG user units and viewport policy |
| What geometry does this SVG element contain? | Browser `getBBox()` | SVG user units |
| Where does it appear after layout and transforms? | Browser `getBoundingClientRect()` or an equivalent automation API | Viewport-relative CSS pixels |
| What is a path's renderer-computed length or point? | `getTotalLength()` or `getPointAtLength()` | SVG user units |
| Which pixels were actually painted? | A deterministic PNG or browser screenshot inspected as raster data | Raster pixels |
| Does the result have the intended balance or density? | Visual inspection at representative outputs | Perceptual; no single bounding box proves it |

Do not compare values from different spaces as if they shared units. Label every recorded measurement with:

```text
kind: geometry | layout | paint
space: svg-user-unit | css-px | raster-px
bounds: x, y, width, height
context: renderer, viewport, DPR, theme, font state
```

## Browser Recipe

Use an installed browser automation facility, preferably Playwright when available, for responsive layout, CSS, text,
and integration-context checks.

1. Open the artifact in the context that owns the reported behavior. A standalone SVG does not reproduce a host page's
   container, inherited CSS, theme, or responsive rules.
2. Fix the viewport, device-pixel ratio, theme, and output scale. Disable animation and wait for the page and fonts to
   settle before measuring.
3. Select the smallest element or group that represents the questioned content. Record its identity with the result.
4. Read `getBBox()` for local SVG geometry and `getBoundingClientRect()` for viewport-relative layout. Use
   `getCTM()` or `getScreenCTM()` to map points into a common space when transforms matter.
5. Capture the same target and surrounding context. A tightly clipped element screenshot can hide incorrect margins,
   overflow, or neighboring alignment.
6. Repeat only the contexts covered by the drawing's contract, such as representative desktop/mobile widths and
   light/dark themes. Use the actual target engine when diagnosing renderer-specific behavior.

`getBBox()` applies geometry attributes but does not apply transforms on the element or its parents.
`getBoundingClientRect()` is an axis-aligned CSS-pixel rectangle after layout and transforms. Do not treat either value
as the exact painted-pixel boundary: strokes, markers, clipping, filters, font rasterization, and antialiasing may require
raster evidence. With rotated or skewed content, transform all relevant corners instead of scaling a width and height.

## Raster Recipe

Use raster evidence when the question concerns visible paint, whitespace, clipping, renderer output, or a pixel-level
regression.

1. Produce a PNG at a fixed viewport or export size, device-pixel ratio, theme, font environment, and background.
   Prefer transparency when the painted foreground must be isolated.
2. Inspect the image visually before reducing it to numbers. Confirm that the selected image contains the intended
   context and that no crop already concealed the defect.
3. When ImageMagick or an equivalent tool is available, derive the occupied-pixel box from the alpha channel or a known
   background. Record the transparency threshold or color tolerance; antialiased edge pixels make that policy part of
   the measurement.
4. Compare occupied bounds, edge margins, and clipping against the stated acceptance criterion. Pixel counts and boxes
   do not measure perceived weight or balance by themselves.
5. Use pixel diffs only with a pinned rendering environment. Font changes, renderer versions, DPR, color management,
   and antialiasing can create noise without a source regression.

For PDF evidence, first validate document structure, then rasterize representative pages through an independent
renderer and apply the same fixed-context checks. Do not convert a raster observation into maintained drawing source.

## Interpret the Result

- Wrong SVG-user-unit geometry points to coordinates, repetition, transforms, or a Sevgi layout helper.
- Correct geometry but wrong CSS-pixel placement points to the viewport, host layout, responsive CSS, or transforms.
- Stable browser boxes but different raster bounds point to paint, clipping, filters, fonts, or renderer behavior.
- Equal boxes with visibly unequal results point to spacing, stroke weight, contrast, or density; keep visual inspection
  as the acceptance criterion.

Do not measure routine API or source-only changes merely because a browser or image tool is available. Stop when the
chosen evidence answers the original question; extra metrics add confidence only when they test another relevant
contract.
