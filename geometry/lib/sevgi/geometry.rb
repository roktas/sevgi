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
  # Screen-space geometry primitives used by Sevgi layout and drawing helpers.
  #
  # Coordinates follow SVG screen conventions: +x points right, +y points down,
  # and positive angles turn clockwise.
  #
  # @example Measure and move a line
  #   line = Sevgi::Geometry::Line.([0, 0], [3, 4])
  #   line.length                    #=> 5.0
  #   line.translate(2, 1).starting #=> Point[2.0, 1.0]
  module Geometry
  end
end
