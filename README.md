[![test status](https://github.com/roktas/sevgi/workflows/Test/badge.svg)](https://github.com/roktas/sevgi/actions?query=workflow%3ATest)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ff0a9c3e65894040800b44867cd28198)](https://app.codacy.com/gh/roktas/sevgi/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# Sevgi

*Scalable Executable Vector Graphics Interface*

Sevgi is a Ruby toolkit for creating SVG through a compact DSL. It uses SVG element names directly, keeping drawings
close to their output while retaining Ruby's composition and reuse.

The full guides, DSL catalog, API reference, and rendered examples are at [sevgi.roktas.dev](https://sevgi.roktas.dev).

## Install

For the complete command-line toolkit, Homebrew is the recommended installation on macOS and Linux:

```sh
brew install roktas/tap/sevgi
```

This installs Sevgi with Ruby, the `sevgi`, `igves`, and `igsev` commands, its native PDF and PNG export stack, and the
headless pdfcpu and Poppler tools. It also gives the packaged agent skill a stable location; `sevgi --skill` prints that
location for agent setup.

When Sevgi is a dependency of a Ruby application, manage it with Bundler in the application's `Gemfile` instead:

```ruby
gem "sevgi"
```

See [Sevgi Appendix](appendix/README.md) for agent-skill and RuboCop setup, including the difference between Homebrew
and versioned gem paths.

## Quick start

Build and render an SVG document:

```ruby
require "sevgi"

drawing = SVG :minimal do
  g id: "group" do
    rect width: 3, height: 5
    circle r: 1
  end
end

puts drawing.Render
```

Library operations use capitalized facade methods such as `SVG.Canvas`; related Ruby types and namespaces use
double-colon names such as `SVG::Canvas`. Executable `.sevgi` scripts promote those operations as bare DSL words.

Sevgi also runs executable `.sevgi` drawing scripts. See [Getting Started](https://sevgi.roktas.dev/getting-started/)
for installation details and [Showcase](https://sevgi.roktas.dev/showcase/) for complete examples with rendered output.
The `sevgi`, `igves`, and `igsev` commands accept a file, `-`, or standard input when no file is given.

## Choose a package

`sevgi` is the umbrella gem. It installs the script runner, the `SVG` facade, the Appendix development extras, and all
runtime component gems. This is the simplest Bundler dependency for applications and drawing scripts:

```ruby
gem "sevgi"
```

The components are also published as separate gems for libraries that need a smaller dependency surface:

| Scenario | Install | Entry point |
| --- | --- | --- |
| Build and render SVG only | `sevgi-graphics` | `require "sevgi/graphics"` |
| Build and validate SVG without the full toolkit | `sevgi-graphics sevgi-standard` | `require "sevgi/graphics"` |
| Use geometry values and transformations without the DSL | `sevgi-geometry` | `require "sevgi/geometry"` |
| Convert SVG or XML back into Sevgi source | `sevgi-derender` | `require "sevgi/derender"` |
| Use grids, rulers, tiles, or export integrations | `sevgi-sundries` | `require "sevgi/sundries"` |
| Package the agent skill or lint `.sevgi` source | `sevgi-appendix` | `require "sevgi/appendix"` or the RuboCop plugin |

For example, a service that only builds SVG can install `sevgi-graphics`. Its focused API is
`Sevgi::Graphics.SVG(...)`; the full `SVG` facade and the `sevgi` executable belong to the umbrella gem. Add
`sevgi-standard` when that focused service should validate element and attribute names. Shared support gems such as
`sevgi-function` are installed transitively by the components that need them. Native PDF and PNG export gems remain
optional when using `sevgi-sundries`. The umbrella gem adds the `sevgi --skill` query for locating the matching
Appendix skill.

## Requirements

Sevgi requires Ruby 3.4 or newer. SVG output has no native graphics dependencies. Gem-based PDF and PNG export uses
optional Cairo, librsvg, and HexaPDF integrations documented in Getting Started.

> [!NOTE]
>
> Sevgi is pre-1.0. Public APIs may still change before the 1.0 release.

## Links

- [Documentation](https://sevgi.roktas.dev)
- [API reference](https://www.rubydoc.info/gems/sevgi)
- [Changelog](CHANGELOG.md)
- [Issue tracker](https://github.com/roktas/sevgi/issues)

## Acknowledgments

Sevgi was inspired by [Victor](https://github.com/DannyBen/victor), which may be a better fit for projects that need a
smaller API. Some Showcase examples were adapted from Victor's examples with thanks to its author.

## License

Sevgi is available under the [GNU General Public License, version 3 or later](LICENSE).
