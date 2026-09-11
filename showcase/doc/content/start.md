+++
title = "Getting Started"
weight = 1
[extra]
group = "Start"
+++

Sevgi creates SVG with Ruby. Use an executable `.sevgi` script when the drawing is the program. Use the library form
when another Ruby application needs the document as a value. The application then decides when and where to render or
write it.

## Create a drawing

Use a script when the drawing is the program, such as a generated asset or build job. The runner supplies Sevgi's
names, and the script usually writes or prints its result:

```ruby
#!/usr/bin/env -S ruby -S sevgi

canvas = Canvas width: 24, height: 24, unit: :px

SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save "badge.svg"
```

Build the document as a library value when another application decides where its rendered string goes:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 24, height: 24, unit: :px

drawing = Sevgi.SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end

File.write "badge.svg", drawing.Render
```

The document block contains the same drawing code in both forms. The constructor and surrounding operations use these
names:

| Role | `.sevgi` script | Ruby library |
| --- | --- | --- |
| Document | `SVG(...)` | `Sevgi.SVG(...)` |
| Canvas | `Canvas(...)` | `SVG.Canvas(...)` |
| Canvas type | `SVG::Canvas` | `SVG::Canvas` |

The script passes its document to `Save`. The application keeps the document and passes its `Render` result to ordinary
Ruby code. [Usage](@/usage.md) explains the two forms, their available names, and how applications can run trusted
`.sevgi` source.

## See a complete drawing

The tabs below use the same files as the test suite. The Ruby tab contains the script. The SVG tab contains its output.

{{<tabs base="meter" dir="../showcase" />}}

## Run an example

If Sevgi is installed on your system, run the example from the checkout:

```bash
sevgi showcase/srv/meter.sevgi
```

To use the gem versions locked by the checkout, run the command through Bundler:

```bash
bundle exec sevgi showcase/srv/meter.sevgi
```

The script writes `showcase/srv/meter.svg` because it ends with `Save`. To write SVG to standard output instead,
use `Out` in the script.

## Install Sevgi

For the complete command-line toolkit, install Sevgi through Homebrew on macOS or Linux:

```bash
brew install roktas/tap/sevgi
```

This installs the `sevgi` executable and Ruby. It also installs the Cairo, librsvg, and HexaPDF export stack. The
package includes the headless pdfcpu and Poppler tools. Inkscape remains an optional external backend.

When Sevgi is a dependency of a Ruby application, add the umbrella gem to its bundle instead:

```ruby
gem "sevgi"
```

The umbrella gem is the right choice for most applications and drawing scripts. It installs the script runner, the
`SVG` facade, the Appendix development extras, and all runtime components.

### Choose a gem

Libraries that need fewer dependencies can install focused component gems:

| Scenario | Install | Require |
| --- | --- | --- |
| Build and render SVG only | `sevgi-graphics` | `require "sevgi/graphics"` |
| Build and validate SVG without the full toolkit | `sevgi-graphics sevgi-standard` | `require "sevgi/graphics"` |
| Use geometry values and transformations without the DSL | `sevgi-geometry` | `require "sevgi/geometry"` |
| Convert SVG or XML back into Sevgi source | `sevgi-derender` | `require "sevgi/derender"` |
| Use grids, rulers, tiles, or export integrations | `sevgi-sundries` | `require "sevgi/sundries"` |
| Package the agent skill or lint `.sevgi` source | `sevgi-appendix` | `require "sevgi/appendix"` or the RuboCop plugin |

For example, a service that only builds SVG can install `sevgi-graphics` and use
`Sevgi::Graphics.SVG(...)`. The full `SVG` facade and the `sevgi` executable belong to the umbrella gem. Add
`sevgi-standard` to validate element and attribute names. Bundler installs shared support gems such as
`sevgi-function` as transitive dependencies. The umbrella gem adds `sevgi --skill` to locate the matching Appendix
skill.

SVG-only library use needs no native graphics packages. The Homebrew package already installs the PDF and PNG
dependencies. Applications that install gems directly must provide the optional `cairo`, `rsvg2`, and `hexapdf` gems
and their system libraries. See the
[`sevgi-sundries` package guide](https://github.com/roktas/sevgi/tree/main/sundries) for those prerequisites.

The full installation also packages Sevgi's agent skill. Run `sevgi --skill` to locate it, then follow the
[Appendix setup guide](https://github.com/roktas/sevgi/tree/main/appendix).

Continue with [Documents](@/documents.md) to choose a canvas and document profile, or browse the tested
[Examples](@/examples.md) for complete drawings.
