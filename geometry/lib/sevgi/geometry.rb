# frozen_string_literal: true

require "sevgi/function"

require_relative "geometry/internal"
require_relative "geometry/errors"

require_relative "geometry/point"
require_relative "geometry/segment"
require_relative "geometry/element"
require_relative "geometry/equation"
require_relative "geometry/operation"

require_relative "geometry/version"

module Sevgi
  # Immutable screen-space geometry values used by Sevgi layout and drawing helpers.
  #
  # Coordinates follow SVG screen conventions: +x points right, +y points down,
  # and positive angles turn clockwise. Constructors accept Point and Segment
  # objects or their two-number Array forms. Transformations return new values;
  # they do not mutate their receiver.
  #
  # Shape constructors have two complementary notations: `Shape[...]` accepts
  # dimensions or segments, while `Shape.(...)` accepts points. Named factories
  # such as `Rect.from_size` and `Rect.from_corners` expose the same distinction
  # when a call site benefits from spelling it out.
  #
  # Trigonometric construction can retain ordinary floating-point noise. Use
  # `approx` for presentation values and `eq?` for precision-aware comparison;
  # strict `==` intentionally compares the exact immutable value.
  #
  # @example Measure and move a line
  #   line = Sevgi::Geometry::Line.([0, 0], [3, 4])
  #   line.length                    #=> 5.0
  #   line.translate(2, 1).starting #=> Point[2.0, 1.0]
  # @example Follow SVG screen directions
  #   origin = Sevgi::Geometry::Point.origin
  #   Sevgi::Geometry::Point.angle(origin, [0, 10]) #=> 90.0
  #   origin.translate(0, 10).below?(origin)        #=> true
  # @see Sevgi::Geometry::Element::Lined
  # @see Sevgi::Geometry::Operation
  # @see https://sevgi.roktas.dev/geometry/ Geometry guide
  module Geometry
  end
end
