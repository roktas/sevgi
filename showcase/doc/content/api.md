+++
title = "API"
weight = 23
[extra]
group = "Reference"
+++

Use the task guides for the workflow and the component reference for exact arguments, return values, and failures.
Sevgi is released as focused gems, so consumers can depend only on the layers they need.

## Find the right reference

| Task | Guide | Component |
| --- | --- | --- |
| Use scripts, the SVG facade, or trusted source execution | [Usage](@/usage.md) | [`sevgi`](https://www.rubydoc.info/gems/sevgi) |
| Construct, profile, and extend SVG documents | [Documents](@/documents.md) | [`sevgi-graphics`](https://www.rubydoc.info/gems/sevgi-graphics) |
| Compose reusable drawing code | [Compose](@/compose.md) | [`sevgi-graphics`](https://www.rubydoc.info/gems/sevgi-graphics) and [`sevgi`](https://www.rubydoc.info/gems/sevgi) |
| Convert, inspect, or import SVG/XML | [Derender](@/derender.md) | [`sevgi-derender`](https://www.rubydoc.info/gems/sevgi-derender) |
| Calculate geometry or hatch shapes | [Geometry](@/geometry.md) | [`sevgi-geometry`](https://www.rubydoc.info/gems/sevgi-geometry) |
| Fit rulers, grids, and tiles | [Layout](@/layout.md) | [`sevgi-sundries`](https://www.rubydoc.info/gems/sevgi-sundries) |
| Render or write SVG, PDF, and PNG | [Output](@/output.md) | [`sevgi-graphics`](https://www.rubydoc.info/gems/sevgi-graphics) and [`sevgi-sundries`](https://www.rubydoc.info/gems/sevgi-sundries) |
| Reuse precision, discovery, shell, or status behavior | [Functions](@/functions.md) | [`sevgi-function`](https://www.rubydoc.info/gems/sevgi-function) |

The executable [DSL Catalog](@/dsl.md) is the canonical inventory of drawing words. It complements the YARD component
references rather than being repeated in them. In the full toolkit, capitalized SVG-domain operations live on the
`SVG` facade and types live beneath `SVG::`; focused component references retain their conventional lowercase APIs.

## Component index

- [`sevgi`](https://www.rubydoc.info/gems/sevgi): the `SVG` facade, promoted script operations, execution, and the
  complete toolkit.
- [`sevgi-graphics`](https://www.rubydoc.info/gems/sevgi-graphics): SVG documents, elements, and the drawing DSL.
- [`sevgi-standard`](https://www.rubydoc.info/gems/sevgi-standard): SVG element and attribute validation.
- [`sevgi-function`](https://www.rubydoc.info/gems/sevgi-function): the supported `Sevgi::F` extension toolbox and its
  returned values.
- [`sevgi-geometry`](https://www.rubydoc.info/gems/sevgi-geometry): immutable geometry values and operations.
- [`sevgi-derender`](https://www.rubydoc.info/gems/sevgi-derender): SVG/XML parsing and Sevgi source generation.
- [`sevgi-sundries`](https://www.rubydoc.info/gems/sevgi-sundries): grids, rulers, tiles, and export tools.
- [`sevgi-showcase`](https://www.rubydoc.info/gems/sevgi-showcase): executable examples and documentation support APIs.
