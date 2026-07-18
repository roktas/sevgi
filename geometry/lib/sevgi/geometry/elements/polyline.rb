# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Polyline.
    # @api private
    PolylineBase = Element.lined(open: true)
    private_constant :PolylineBase

    # Variable-size open lined element with at least two points.
    # @!method self.[](*segments, position: Origin)
    #   Builds a polyline from ordered segments.
    #   @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] ordered segments
    #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
    #   @return [Sevgi::Geometry::Polyline]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a polyline
    # @!method self.call(*points)
    #   Builds a polyline from ordered points.
    #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] ordered points
    #   @return [Sevgi::Geometry::Polyline]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a polyline
    # @!method self.from_segments(*segments, position: Origin)
    #   Builds a polyline from ordered segments.
    #   @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] ordered segments
    #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
    #   @return [Sevgi::Geometry::Polyline]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a polyline
    # @!method self.from_points(*points)
    #   Builds a polyline from ordered points.
    #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] ordered points
    #   @return [Sevgi::Geometry::Polyline]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a polyline
    # @example Pair mathematical notation with English conveniences
    #   Sevgi::Geometry::Polyline[[2, 0], [1, 90]] == Sevgi::Geometry::Polyline.from_segments([2, 0], [1, 90])
    #   Sevgi::Geometry::Polyline.([0, 0], [2, 0]) == Sevgi::Geometry::Polyline.from_points([0, 0], [2, 0])
    # @example Measure and query an open path
    #   path = Sevgi::Geometry::Polyline.([0, 0], [3, 0], [3, 4])
    #   path.length         # => 7.0
    #   path.on?([2, 0])    # => true
    #   path.inside?([1, 1]) # => false
    class Polyline < PolylineBase
      private

      def validate_geometry!
        Error.("Polyline requires at least two points") if points.size < 2
      end
    end
  end
end
