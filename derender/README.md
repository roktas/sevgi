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
Sevgi::Derender.derender(source)

source = '<svg><rect id="mark" style="fill: red" width="3"/></svg>'
Sevgi::Derender.derender(source, omit: %i[id style])
```

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

This gem needs no native libraries of its own. Nokogiri may use platform packages depending on the target Ruby platform.

## Links

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-derender>
- Source: <https://github.com/roktas/sevgi/tree/main/derender>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
