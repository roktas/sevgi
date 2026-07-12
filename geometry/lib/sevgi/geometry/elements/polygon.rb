# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Polygon.
    # @api private
    PolygonBase = Element.lined
    private_constant :PolygonBase

    # Variable-size closed lined element with at least three vertices.
    # @example Pair point notation with its English convenience
    #   points = [[0, 0], [2, 0], [1, 1]]
    #   segments = Polygon.(*points).segments
    #   Polygon[*segments] == Polygon.from_segments(*segments)
    #   Polygon.(*points) == Polygon.from_points(*points)
    class Polygon < PolygonBase
      private

      def validate_geometry!
        Error.("Polygon requires at least three vertices") if points.size < 4
      end
    end
  end
end
