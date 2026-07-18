# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Polygon.
    # @api private
    PolygonBase = Element.lined
    private_constant :PolygonBase

    # Variable-size closed lined element with at least three vertices.
    # @!method self.[](*segments, position: Origin)
    #   Builds a polygon from boundary segments.
    #   @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] boundary segments
    #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
    #   @return [Sevgi::Geometry::Polygon]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a polygon
    # @!method self.call(*points)
    #   Builds a polygon from boundary points.
    #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points without a repeated closing point
    #   @return [Sevgi::Geometry::Polygon]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a polygon
    # @!method self.from_segments(*segments, position: Origin)
    #   Builds a polygon from boundary segments.
    #   @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] boundary segments
    #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
    #   @return [Sevgi::Geometry::Polygon]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a polygon
    # @!method self.from_points(*points)
    #   Builds a polygon from boundary points.
    #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points without a repeated closing point
    #   @return [Sevgi::Geometry::Polygon]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a polygon
    # @!method perimeter
    #   Returns the closed path perimeter.
    #   @return [Float]
    # @example Pair point notation with its English convenience
    #   points = [[0, 0], [2, 0], [1, 1]]
    #   segments = Sevgi::Geometry::Polygon.(*points).segments
    #   Sevgi::Geometry::Polygon[*segments] == Sevgi::Geometry::Polygon.from_segments(*segments)
    #   Sevgi::Geometry::Polygon.(*points) == Sevgi::Geometry::Polygon.from_points(*points)
    # @example Classify points against a closed boundary
    #   polygon = Sevgi::Geometry::Polygon.([0, 0], [6, 0], [3, 4])
    #   polygon.inside?([3, 2]) # => true
    #   polygon.on?([3, 0])     # => true
    #   polygon.outside?([7, 2]) # => true
    class Polygon < PolygonBase
      private

      def validate_geometry!
        Error.("Polygon requires at least three vertices") if points.size < 4
      end
    end
  end
end
