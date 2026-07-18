[![test status](https://github.com/roktas/sevgi/workflows/Test/badge.svg)](https://github.com/roktas/sevgi/actions?query=workflow%3ATest)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ff0a9c3e65894040800b44867cd28198)](https://app.codacy.com/gh/roktas/sevgi/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# Sevgi

Sevgi is a Ruby toolkit for creating SVG through a compact DSL. It uses SVG element names directly, keeping drawings
close to their output while retaining Ruby's composition and reuse.

The full guides, DSL catalog, API reference, and rendered examples are at [sevgi.roktas.dev](https://sevgi.roktas.dev).

## Quick start

Install Sevgi:

```sh
gem install sevgi
```

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

## Requirements

Sevgi requires Ruby 3.4 or newer. SVG output has no native graphics dependencies; PDF and PNG export use optional
Cairo, librsvg, and HexaPDF integrations documented in Getting Started.

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
