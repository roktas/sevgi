# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Polygon.
    # @api private
    PolygonBase = Element.lined
    private_constant :PolygonBase

    # Variable-size closed lined element.
    class Polygon < PolygonBase
    end
  end
end
