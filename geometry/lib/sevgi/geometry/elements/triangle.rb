# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Triangle.
    # @api private
    TriangleBase = Element.lined(3)
    private_constant :TriangleBase

    # Closed three-sided element built from non-collinear segments or points. Every construction path rejects
    # degenerate triangles; affine operations retain Triangle when the transformed points remain non-degenerate.
    # @!method self.call(*points)
    #   Builds a triangle from three boundary points.
    #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] three boundary points
    #   @return [Sevgi::Geometry::Triangle]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or form a degenerate triangle
    # @!method self.from_segments(segment_a, segment_b, position: Origin)
    #   Builds a triangle from two adjacent segments and derives the closing side.
    #   @param segment_a [Sevgi::Geometry::Segment, Array<Numeric>] first adjacent segment
    #   @param segment_b [Sevgi::Geometry::Segment, Array<Numeric>] second adjacent segment
    #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
    #   @return [Sevgi::Geometry::Triangle]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or form a degenerate triangle
    # @!method self.from_points(*points)
    #   Builds a triangle from three boundary points.
    #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] three boundary points
    #   @return [Sevgi::Geometry::Triangle]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or form a degenerate triangle
    # @!attribute [r] A
    #   @return [Sevgi::Geometry::Point] first vertex
    # @!attribute [r] B
    #   @return [Sevgi::Geometry::Point] second vertex
    # @!attribute [r] C
    #   @return [Sevgi::Geometry::Point] third vertex
    # @!attribute [r] AB
    #   @return [Sevgi::Geometry::Line] side from A to B
    # @!attribute [r] BC
    #   @return [Sevgi::Geometry::Line] side from B to C
    # @!attribute [r] CA
    #   @return [Sevgi::Geometry::Line] side from C to A
    # @!method perimeter
    #   Returns the closed path perimeter.
    #   @return [Float]
    # @example Pair mathematical notation with English conveniences
    #   Triangle[[2, 0], [2, 90]] == Triangle.from_segments([2, 0], [2, 90])
    #   Triangle.([0, 0], [2, 0], [2, 2]) == Triangle.from_points([0, 0], [2, 0], [2, 2])
    class Triangle < TriangleBase
      # Builds a triangle from two adjacent segments.
      #
      # The closing segment is the direct vector from the end of `segment_b`
      # back to `position`. Segment order controls orientation; reversing the
      # inputs returns the corresponding opposite orientation. Zero-length or
      # collinear inputs are rejected using the current numeric precision.
      # @param segment_a [Sevgi::Geometry::Segment, Array<Numeric>] first segment
      # @param segment_b [Sevgi::Geometry::Segment, Array<Numeric>] second segment
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Triangle]
      # @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced, or the segments are degenerate
      def self.[](segment_a, segment_b, position: Origin)
        a, b = Tuples[Segment, segment_a, segment_b]

        validate!(a, b)
        new_by_segments(a, b, closing_segment(a, b), position:)
      end

      class << self
        private

        def closing_segment(a, b)
          Segment.(b.ending(a.ending(Origin)), Origin)
        end

        def cross(a, b) = (a.x * b.y) - (a.y * b.x)

        def validate!(a, b)
          if F.zero?(a.length) ||
              F.zero?(b.length) ||
              F.zero?(cross(a, b))
            Error.("Triangle segments must form a non-degenerate triangle")
          end
        end
      end

      private

      def validate_geometry!
        self.class.send(:validate!, segments[0], segments[1])
      end
    end
  end
end
