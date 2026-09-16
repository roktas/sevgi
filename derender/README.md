# Sevgi Derender

Sevgi Derender converts SVG or XML back into Sevgi DSL source.

## Install

```sh
gem install sevgi-derender
```

## Require

```ruby
require "sevgi/derender"
```

## Example

```ruby
source = "<svg><rect width=\"3\" height=\"5\"/></svg>"
puts Sevgi::Derender.derender(source)
# SVG do
#   rect width: 3, height: 5
# end

source = '<svg><rect id="mark" style="fill: red" width="3"/></svg>'
puts Sevgi::Derender.derender(source, omit: %i[id style])
# SVG do
#   rect width: 3
# end
```

Use `decompile` to inspect an immutable parsed node. Use `evaluate` to add a selected node directly to an existing
Sevgi document. Generated source is ordinary Ruby. Review it and integrate it statically instead of evaluating it
dynamically.

Derender reads the XML encoding declaration or byte-order mark. Generated Ruby and rendered XML use UTF-8.
The XML declaration keeps its version and standalone flag, with any encoding field changed to UTF-8.

## Executable

```sh
igves --omit id --omit style drawing.svg
```

Omit the file or pass `-` to read SVG from standard input:

```sh
igves --omit id < drawing.svg
```

`igves` prints generated Sevgi source. The umbrella `sevgi` gem also installs `igsev`, which evaluates that source and
prints normalized SVG:

```sh
igsev --omit id --omit style < drawing.svg
```

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs no native libraries of its own. Nokogiri can use platform packages on some Ruby platforms.

## Links

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-derender>
- Source: <https://github.com/roktas/sevgi/tree/main/derender>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
