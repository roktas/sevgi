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
   drawing geometry, viewport, transforms, styles, strokes, and renderer behavior. Fix the layer that owns the faulty
   contract. Do not hide it with empty margins, oversized frames, clipping, non-uniform scaling, or a one-case offset.
3. **Stay native to Sevgi.** Use SVG elements through the Sevgi DSL and prefer Sevgi's existing Graphics, Geometry,
   Sundries, and Function helpers where they fit. Do not generate raw SVG/XML, another graphics format, or an
   intermediate string and then convert it into Sevgi. Use Derender only when existing SVG/XML is a genuine input
   artifact. Treat Ruby's dynamic evaluation APIs (`eval`, `*_eval`, and `*_exec`) as anti-patterns throughout every
   Derender workflow. Use `Include` or `IncludeChildren` when the editor file remains authoritative, an `Evaluate*`
   operation when the target must be explicit, or reviewed source integrated statically into the maintained DSL.

## Workflow

1. Determine the host and installed dependency surface: executable `.sevgi` script, full-toolkit Ruby library, or a
   focused component. Read [dsl.md](references/dsl.md) for its grammar and facade boundaries.
2. Before introducing an operation, make sure that the target version documents its name, signature, required profile, and component.
   Read [toolkit.md](references/toolkit.md) for lookup paths or before replacing a Sevgi helper.
   Do not infer an API from an English name or use `Element` to bypass an unknown operation.
3. Before changing a drawing, state the visible target and the properties that must remain unchanged.
   Keep these acceptance criteria through verification. Equal canvas dimensions do not substitute for equal visible size.
4. Read only the references needed for the operation. Use [ruby.md](references/ruby.md) for helpers, callable modules,
   document extensions, or DSL formatting. Before adding visual arithmetic, offsets, or scaling, read
   [drawing.md](references/drawing.md). Use [svg.md](references/svg.md) to find a renderer-owned mechanism.
5. Read [layout.md](references/layout.md) for repetition, tiling, alignment, rulers, grids, `Draw`, or hatching.
6. For editor-authored SVG/XML, `igves` prints Sevgi source. `igsev` round-trips to normalized SVG. Both accept files or
   standard input. Read [derender.md](references/derender.md). For PDF/PNG output, read [output.md](references/output.md).
7. Write the smallest clear Sevgi expression. Keep case-sensitive, normally lowercase-leading SVG element calls,
   capitalized Sevgi operations, ordinary Ruby control flow, and SVG attributes visibly distinct. Do not mechanically
   parenthesize statement-like DSL calls. When braces would require those parentheses, use `do`/`end`.
8. Use the verification boundaries in [dsl.md](references/dsl.md). Report unavailable checks rather than claiming they passed.
9. For new or visually changed drawings, render and inspect the supported contexts affected by the change.
   Compare the output against the original acceptance criteria. For size, alignment, clipping, density, or visual-regression
   evidence, read [inspection.md](references/inspection.md) before choosing a measurement tool.
   Do not require visual measurements for source-only changes with no effect on rendering.
10. Re-read the finished source for raw-XML detours, avoidable calculations, magic offsets, duplicated helpers, and
    stale artifacts.

## References

| Need | Read |
| --- | --- |
| Choose script/library syntax, profiles, SVG elements, or Sevgi DSL words | [dsl.md](references/dsl.md) |
| Choose a component and locate user, YARD, or checkout documentation | [toolkit.md](references/toolkit.md) |
| Structure `.sevgi` and library code as idiomatic Ruby | [ruby.md](references/ruby.md) |
| Apply the renderer/program ownership boundary and diagnose visual mismatches | [drawing.md](references/drawing.md) |
| Measure SVG geometry, browser layout, or painted pixels | [inspection.md](references/inspection.md) |
| Find an SVG capability and its authoritative specification | [svg.md](references/svg.md) |
| Choose repetition, tiling, ruler, grid, Draw, pattern, or Hatch | [layout.md](references/layout.md) |
| Integrate editor-authored SVG/XML through Derender | [derender.md](references/derender.md) |
| Render, save, or export SVG, PDF, or PNG | [output.md](references/output.md) |
