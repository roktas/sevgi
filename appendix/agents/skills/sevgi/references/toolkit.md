# Toolkit Routing

## Choose the Owner

| Need | Component / entry point | Boundary |
| --- | --- | --- |
| Build SVG documents and element trees | Graphics; `SVG(...)`, SVG element calls | Default starting point for every drawing |
| Choose paper size, canvas geometry, or root serialization metadata | `SVG.Paper`, `SVG.Canvas`, `SVG.Document` | Keep physical size, drawing surface, and document profile independent |
| Validate SVG vocabulary and nesting | Standard | Use validation; do not hand-maintain element/attribute allowlists |
| Calculate geometry SVG cannot supply | `Sevgi::Geometry` | Use for constructed values, intersections, sweeps, and algorithmic bounds—not renderer layout |
| Fit rulers, grids, and reusable tile layouts | `Sevgi::Sundries`, `SVG.Grid` | Choose the exact model through `layout.md` |
| Reuse supported cross-component helpers | `Sevgi::F` | Check before adding a project-local Sevgi helper; it is not a general utility library |
| Import or inspect existing SVG/XML | Derender facade methods | Choose the source/evaluation relationship through `derender.md` |
| Render SVG as PDF or PNG | Sundries export / document `PDF` and `PNG` | Choose the output boundary through `output.md` |

Before reimplementing shared behavior, check `Sevgi::F` for degree trigonometry and precision, `.sevgi` discovery,
generated-file I/O, argv-safe child processes, Sevgi-facing names, and status output.

## In a Checkout

When a Sevgi checkout is available, prefer its canonical sources:

| Need | Source |
| --- | --- |
| Machine-readable DSL inventory and examples | `showcase/doc/data/dsl.yml` |
| Task-oriented user semantics | `showcase/doc/content/` |
| Runnable complete drawings | examples under `showcase/srv` that are linked from the user docs or DSL catalog |
| Exact public contracts | the owning component's `lib/` YARD comments |
| Rendered local YARD | `.cache/ruby/doc/api` after `bundle exec rake doc` |

## Lookup Order

1. Read the task-relevant user guide for semantics and workflow.
2. Search the structured DSL inventory and linked runnable Showcase examples for the nearest drawing pattern.
3. Read the rendered DSL catalog for an exact drawing word and executable example.
4. Read YARD for signatures, return values, and failure contracts.
5. Read MDN or the SVG specification for renderer behavior.

| Topic | User guide | YARD |
| --- | --- | --- |
| Script and library forms | [Getting Started](https://sevgi.roktas.dev/getting-started/), [Library Mode](https://sevgi.roktas.dev/library-mode/) | [`sevgi`](https://www.rubydoc.info/gems/sevgi) |
| SVG documents and DSL | [SVG Essentials](https://sevgi.roktas.dev/svg/), [DSL Catalog](https://sevgi.roktas.dev/dsl/) | [`sevgi-graphics`](https://www.rubydoc.info/gems/sevgi-graphics) |
| Geometry | [Geometry](https://sevgi.roktas.dev/geometry/) | [`sevgi-geometry`](https://www.rubydoc.info/gems/sevgi-geometry) |
| Rulers, grids, tiles, export | [Sundries](https://sevgi.roktas.dev/sundries/) | [`sevgi-sundries`](https://www.rubydoc.info/gems/sevgi-sundries) |
| Shared helpers | [Functions](https://sevgi.roktas.dev/functions/) | [`sevgi-function`](https://www.rubydoc.info/gems/sevgi-function) |
| SVG/XML import and round trip | [Derender](https://sevgi.roktas.dev/derender/) | [`sevgi-derender`](https://www.rubydoc.info/gems/sevgi-derender) |

When working in a Sevgi checkout, prefer the checked-out docs and source over an installed gem's online YARD version.
