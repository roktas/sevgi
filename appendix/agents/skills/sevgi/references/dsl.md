# DSL Map

## Host Grammar

| Form | Meaning |
| --- | --- |
| `rect`, `circle`, `linearGradient`, `clipPath`, ... | Standard SVG elements created by exact, case-sensitive names that normally start lowercase |
| `Translate`, `Tile`, `Call`, `Render`, ... | Sevgi operations, normally capitalized to stand apart from SVG elements |
| `css`, `square`, `symbol!`, `layer`, `layer!`, `base` | Examples of deliberate lowercase Sevgi words. The DSL catalog owns the full list |
| `SVG(...)` | Build a document in both script and library code |
| `SVG.Canvas(...)` | Call a full-toolkit facade operation in library code |
| `SVG.Module { ... }` | Build an anonymous callable with public steps and private or protected helpers |
| `extend SVG::Module` | Apply the same callable contract to an existing or explicitly declared module |
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
| Focused graphics library | `require "sevgi/graphics"` | `Sevgi::Graphics.SVG` and lowercase component constructors without the full `SVG` facade |

Follow the consumer's declared gems and existing dialect. Do not require the full toolkit merely to obtain facade
spelling, and do not use facade operations when only a focused component is installed.

`SVG(...)` is the default constructor in library code as well as scripts. If another method shadows that name, use
`Sevgi.SVG(...)`. The explicit receiver is supported but not required. `SVG.Canvas(...)` is a separate facade operation.

## Minimal Forms

Executable script:

```ruby
#!/usr/bin/env -S ruby -S sevgi

canvas = Canvas width: 24, height: 24, unit: :px

SVG :default, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save "badge.svg"
```

Ruby library:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 24, height: 24, unit: :px
drawing = SVG :default, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end

File.write "badge.svg", drawing.Render
```

## Paper, Canvas, and Document

Keep physical size and serialization dialect independent:

| Need | Use | Owns |
| --- | --- | --- |
| Register a named physical size | `SVG.Paper` / script `Paper` | width, height, and unit |
| Look up a registered physical size | `SVG::Paper.fetch` | the registered size value |
| Build one drawing surface | `SVG.Canvas` / script `Canvas` | size, margins, unit, name, and resulting `viewBox` |
| Define or select an SVG document profile | `SVG.Document` / script `Document` | root attributes and preambles |

The first argument to `SVG` selects a document profile. The optional second argument supplies a canvas. Use an
anonymous `Document` for one-off metadata. Use a named profile only for shared process-wide vocabulary. Prefer
non-bang registration. Use `Paper!` or `Document!` only for an intentional overwrite.

A canvas's `viewBox` starts at the negative left and top margins. Drawing coordinates remain relative to the inner
area. For example, `SVG.Canvas(width: 40, height: 20, unit: :px, margins: 2)` starts at `(-2, -2)`.
With `margins: -2`, it starts at `(2, 2)` instead. Negative margins enlarge the inner area, not the viewport.

## Task-to-Word Map

| Task | Start with |
| --- | --- |
| Create SVG structure | SVG element names with blocks for nested containers |
| Choose page dimensions and document metadata | `Paper`, `Canvas`, and `Document` with separate responsibilities |
| Set reusable styles | `css`, classes, presentation attributes |
| Transform an element or group | `Translate`, `Rotate`, `Scale`, `Skew`, `Flip` |
| Center known inner and outer boxes | element `Align`, or `Sevgi::Geometry::Operation` for edge alignment or a Ruby result |
| Draw simple line/path wrappers | `LineTo`, `LineBy`, `HLineTo`, `HLineBy`, `VLineTo`, `VLineBy` |
| Reuse or repeat drawing | `defs`/`use`, `Tile`, `TileX`, `TileY`, `Duplicate` |
| Compose reusable drawing code | `SVG.Module`, `SVG::Module`, `base`, `Call`, and profile-specific wrappers |
| Move existing element trees | `Append`, `Prepend`, `Adopt`, `AdoptFirst`, `Orphan` |
| Draw or hatch Geometry values | `Draw`, `Hatch` on `:inkscape` or an explicitly extended custom profile |
| Inspect or validate output | `Identifiers`, `Validate`, `Lint` |
| Produce output | `Render`, `Out`, `Save`, and optional `PDF` or `PNG` export |
| Import existing SVG/XML | `Include`, `Evaluate`, `Derender`, `Decompile` and their file variants |

## Verification Boundaries

| Check | Establishes | Does not establish |
| --- | --- | --- |
| `Validate` | SVG vocabulary and nesting compliance when Standard is available | Visual correctness; without Standard it returns `nil` and performs no validation |
| `Lint` | No duplicate visible IDs | Complete reference integrity or SVG standard compliance |
| `Render` | SVG serialization | Correct appearance in a browser or export engine |
| Visual inspection | Appearance in the inspected context | Correctness in untested contexts |

For a new or changed drawing, run `Lint` and, when Standard is available, `Validate` before accepting the output.
Report a missing Standard component as unavailable validation, not a successful check.
Inspect visually changed output against the user's acceptance criteria.

## Profiles

| Profile | Use |
| --- | --- |
| `:minimal` | SVG without default preamble or namespace metadata |
| `:default` | Standalone SVG with XML declaration and SVG namespace |
| `:html` | SVG intended for HTML embedding |
| `:inkscape` | Editor metadata plus convenient `Draw` and `Hatch` helpers |

Do not invent a Sevgi word from a likely name. Check the [online DSL catalog](https://sevgi.roktas.dev/dsl/) for
executable examples and the appropriate YARD component reference for exact arguments and return values.
