# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Polygon.
    # @api private
    PolygonBase = Element.lined
    private_constant :PolygonBase

    # Variable-size closed lined element with at least three vertices.
    class Polygon < PolygonBase
      private

      def validate_geometry!
        Error.("Polygon requires at least three vertices") if points.size < 4
      end
    end
  end
end
