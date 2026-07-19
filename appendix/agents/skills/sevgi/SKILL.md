---
name: sevgi
description: Create, edit, review, and debug SVG drawings written with the Sevgi Ruby DSL. Use for `.sevgi` scripts, Ruby code that builds SVG with Sevgi, reusable drawing modules, editor-authored SVG/XML integration through Derender, PDF or PNG export, visual regressions, or requests to express an SVG design through Sevgi rather than raw XML.
---

# Sevgi

Sevgi is first a Ruby DSL: write idiomatic Ruby that describes SVG while preserving SVG semantics and the user's
visible intent.

## Core Contract

1. **Delegate rendering to SVG.** Before calculating any value that affects appearance, decide who owns that result. If
   SVG can express the intent and the final value depends on renderer knowledge, encode the intent in SVG and let the
   renderer resolve it. Use Ruby or `Sevgi::Geometry` only for information the program genuinely must derive. Read
   [drawing.md](references/drawing.md) before adding rendering-related arithmetic.
2. **Fix the cause, not the symptom.** Treat the visible result as the acceptance criterion. Trace a mismatch through
   drawing geometry, viewport, transforms, styles, strokes, and renderer behavior; fix the layer that owns the faulty
   contract. Do not hide it with empty margins, oversized frames, clipping, non-uniform scaling, or a one-case offset.
3. **Stay native to Sevgi.** Use SVG elements through the Sevgi DSL and prefer Sevgi's existing Graphics, Geometry,
   Sundries, and Function helpers where they fit. Do not generate raw SVG/XML, another graphics format, or an
   intermediate string and then convert it into Sevgi. Use Derender only when existing SVG/XML is a genuine input
   artifact.

## Workflow

1. Determine the host and installed dependency surface: executable `.sevgi` script, full-toolkit Ruby library, or a
   focused component. Read [dsl.md](references/dsl.md) for its grammar and facade boundaries.
2. Choose the component that owns each nontrivial operation. Read [toolkit.md](references/toolkit.md) before writing a
   project-local substitute for a Sevgi helper.
3. Structure data, control flow, and reuse as ordinary Ruby while preserving the DSL shape. Read
   [ruby.md](references/ruby.md).
4. Identify the owner of each visual result before writing arithmetic, offsets, or scaling. Read
   [drawing.md](references/drawing.md), and use [svg.md](references/svg.md) when SVG may own the behavior.
5. Read [layout.md](references/layout.md) for repetition, tiling, alignment, rulers, grids, drawing, or hatching.
6. For editor-authored SVG/XML, read [derender.md](references/derender.md). For PDF/PNG output, read
   [output.md](references/output.md).
7. Before introducing a Sevgi word or signature not established by nearby code or the loaded references, verify it in
   the DSL catalog or owning YARD. Do not infer an API from an English name or use `Element` to bypass an unknown
   operation.
8. Write the smallest clear Sevgi expression. Keep case-sensitive, normally lowercase-leading SVG element calls,
   capitalized Sevgi operations, ordinary Ruby control flow, and SVG attributes visibly distinct. Do not mechanically
   parenthesize statement-like DSL calls.
9. Render and inspect the actual output in each context it claims to support. Compare visible bounds and density—not
   only canvas or DOM dimensions. For size, alignment, clipping, density, or visual-regression evidence, read
   [inspection.md](references/inspection.md) and identify the measurement space before choosing a tool.
10. Re-read the finished source for raw-XML detours, avoidable calculations, magic offsets, duplicated helpers, and
    stale artifacts.

## References

| Need | Read |
| --- | --- |
| Choose script/library syntax, profiles, SVG elements, or Sevgi DSL words | [dsl.md](references/dsl.md) |
| Choose a component and locate user, YARD, or checkout documentation | [toolkit.md](references/toolkit.md) |
| Structure `.sevgi` and library code as idiomatic Ruby | [ruby.md](references/ruby.md) |
| Apply the renderer/program ownership boundary; diagnose visual mismatches | [drawing.md](references/drawing.md) |
| Measure SVG geometry, browser layout, or painted pixels | [inspection.md](references/inspection.md) |
| Find an SVG capability and its authoritative specification | [svg.md](references/svg.md) |
| Choose repetition, tiling, ruler, grid, Draw, pattern, or Hatch | [layout.md](references/layout.md) |
| Integrate editor-authored SVG/XML through Derender | [derender.md](references/derender.md) |
| Render, save, or export SVG, PDF, or PNG | [output.md](references/output.md) |
