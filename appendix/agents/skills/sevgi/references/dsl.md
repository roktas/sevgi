# DSL Map

## Host Grammar

| Form | Meaning |
| --- | --- |
| `rect`, `circle`, `linearGradient`, `clipPath`, ... | Standard SVG elements created directly by exact, case-sensitive names; they normally start lowercase |
| `Translate`, `Tile`, `Call`, `Render`, ... | Sevgi operations, normally capitalized to stand apart from SVG elements |
| `css`, `layer`, `layer!`, `base` | Deliberate lowercase Sevgi words; `base` belongs to callable-module definitions |
| `SVG(...)` | Build a document in both script and library code |
| `SVG.Canvas(...)` | Call a full-toolkit facade operation in library code |
| `SVG::Canvas` | Refer to a type or namespace |
| `Canvas(...)` | Call the promoted operation in an executable `.sevgi` script |

Use Ruby hashes for SVG attributes. Quote hyphenated SVG names:

```ruby
text "Ready", x: 12, y: 16, "text-anchor": "middle", "font-weight": "bold"
```

## Dependency Surface

| Host | Load | Vocabulary |
| --- | --- | --- |
| Executable script | `ruby -S sevgi` through the `.sevgi` shebang | bare promoted operations such as `Canvas`, `Paper`, and `Grid` |
| Full-toolkit library | `require "sevgi"` | `SVG(...)` plus facade operations such as `SVG.Canvas` and `SVG.Grid` |
| Focused graphics library | `require "sevgi/graphics"` | `Sevgi::Graphics.SVG` and lowercase component constructors; no full `SVG` facade |

Follow the consumer's declared gems and existing dialect. Do not require the full toolkit merely to obtain facade
spelling, and do not use facade operations when only a focused component is installed.

## Minimal Forms

Executable script:

```ruby
#!/usr/bin/env -S ruby -S sevgi

canvas = Canvas width: 24, height: 24, unit: :px

SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save "badge.svg"
```

Ruby library:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 24, height: 24, unit: :px
drawing = SVG(:minimal, canvas) { circle cx: 12, cy: 12, r: 10, fill: "tomato" }

File.write "badge.svg", drawing.Render
```

## Paper, Canvas, and Document

Keep physical size and serialization dialect independent:

| Need | Use | Owns |
| --- | --- | --- |
| Register or look up a named physical size | `SVG.Paper` / script `Paper` | width, height, and unit |
| Build one drawing surface | `SVG.Canvas` / script `Canvas` | size, margins, unit, name, and resulting `viewBox` |
| Define or select an SVG document profile | `SVG.Document` / script `Document` | root attributes and preambles |

The first argument to `SVG` selects a document profile; the optional second argument supplies a canvas. Use an
anonymous `Document` for one-off metadata and a named profile only for shared process-wide vocabulary.
Prefer non-bang registration; use `Paper!` or `Document!` only for an intentional overwrite.

## Task-to-Word Map

| Task | Start with |
| --- | --- |
| Create SVG structure | SVG element names; nest containers with blocks |
| Choose page dimensions and document metadata | `Paper`, `Canvas`, `Document`; keep their responsibilities separate |
| Set reusable styles | `css`, classes, presentation attributes |
| Transform an element or group | `Translate`, `Rotate`, `Scale`, `Skew`, `Flip` |
| Center known inner and outer boxes | element `Align`; use `Sevgi::Geometry::Operation` for edge alignment or a Ruby result |
| Draw simple line/path wrappers | `LineTo`, `LineBy`, `HLineTo`, `HLineBy`, `VLineTo`, `VLineBy` |
| Reuse or repeat drawing | `defs`/`use`, `Tile`, `TileX`, `TileY`, `Duplicate` |
| Compose reusable drawing code | `SVG::Module`, `base`, `Call`; profile-specific `Group`, `Layer`, `Layer!`, `Symbols` |
| Move existing element trees | `Append`, `Prepend`, `Adopt`, `AdoptFirst`, `Orphan` |
| Draw or hatch Geometry values | `Draw`, `Hatch` on `:inkscape` or an explicitly extended custom profile |
| Inspect or validate output | `Identifiers`, `Validate`, `Lint` |
| Produce output | `Render`, `Out`, `Save`; optional `PDF` and `PNG` export |
| Import existing SVG/XML | `Include`, `Evaluate`, `Derender`, `Decompile` and their file variants |

## Profiles

| Profile | Use |
| --- | --- |
| `:minimal` | SVG without default preamble or namespace metadata |
| `:default` | Standalone SVG with XML declaration and SVG namespace |
| `:html` | SVG intended for HTML embedding |
| `:inkscape` | Editor metadata plus convenient `Draw` and `Hatch` helpers |

Do not invent a Sevgi word from a likely name. Check the [online DSL catalog](https://sevgi.roktas.dev/dsl/) for
executable examples and the appropriate YARD component reference for exact arguments and return values.
