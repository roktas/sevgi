# frozen_string_literal: true

module Sevgi
  module Geometry
    # Complete circular boundary with a positive radius and a center.
    # Uniform scaling preserves Circle. General affine transforms can return Ellipse.
    # @example Create an upper semicircle from a circle
    #   Sevgi::Geometry::Circle[10].arc(starting_angle: 180, extent: 180)
    class Circle < Ellipse
      # Builds a circle from its radius and center.
      # @param radius [Numeric] positive finite radius
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] circle center
      # @return [Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when radius or position is invalid
      def self.[](radius, position: Origin) = new(radius, radius, position:, rotation: 0)

      # Draws a native SVG circle without rounding the geometry.
      # @param node [Object] graphics node receiving the circle
      # @param attributes [Hash] SVG attributes
      # @return [Object] graphics command result
      def draw(node, **attributes) = node.circle(cx: position.x, cy: position.y, r: radius, **attributes)

      # Returns the circle radius.
      # @return [Float]
      def radius = rx
    end
  end
end
