# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Polyline.
    # @api private
    PolylineBase = Element.lined(open: true)
    private_constant :PolylineBase

    # Variable-size open lined element.
    class Polyline < PolylineBase
    end
  end
end
