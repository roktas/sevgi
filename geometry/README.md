# Sevgi Geometry

Sevgi Geometry provides the small set of geometric values and operations used by Sevgi drawings.

## Install

```sh
gem install sevgi-geometry
```

## Require

```ruby
require "sevgi/geometry"
```

## Example

```ruby
rect = Sevgi::Geometry::Rect[3, 5]
rect.box.width                 # => 3.0
rect.translate(2, 1).position # => Point[2.0, 1.0]
```

Geometry uses SVG screen coordinates. Positive x goes right, positive y goes down, and positive angles turn clockwise.
Operations return new immutable values.

`Ellipse` and `Circle` describe closed boundaries. `Arc` selects a finite, directed part of an ellipse:

```ruby
ellipse = Sevgi::Geometry::Ellipse[40, 20, position: [50, 30]]
arc = ellipse.arc starting_angle: 180, extent: 120
arc.box
arc.length
arc.intersection Sevgi::Geometry::Equation.vertical(50)
```

Positive extent turns clockwise. Its absolute value must be less than 360 degrees.
Bounds and length do not depend on display precision. Closed ellipses and circles also support line sweeps.

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs only Ruby and its Ruby dependencies.

## Links

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-geometry>
- Source: <https://github.com/roktas/sevgi/tree/main/geometry>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
