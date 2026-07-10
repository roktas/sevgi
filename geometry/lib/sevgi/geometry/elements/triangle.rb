# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Triangle.
    # @api private
    TriangleBase = Element.lined(3)
    private_constant :TriangleBase

    # Closed three-sided element built from two non-collinear adjacent segments.
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

      def self.closing_segment(a, b)
        Segment.(b.ending(a.ending(Origin)), Origin)
      end

      def self.cross(a, b) = (a.x * b.y) - (a.y * b.x)

      def self.validate!(a, b)
        if F.zero?(a.length) ||
            F.zero?(b.length) ||
            F.zero?(cross(a, b))
          Error.("Triangle segments must form a non-degenerate triangle")
        end
      end

      private_class_method :closing_segment, :cross, :validate!
    end
  end
end
