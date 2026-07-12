# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Polyline.
    # @api private
    PolylineBase = Element.lined(open: true)
    private_constant :PolylineBase

    # Variable-size open lined element with at least two points.
    class Polyline < PolylineBase
      private

      def validate_geometry!
        Error.("Polyline requires at least two points") if points.size < 2
      end
    end
  end
end
