# frozen_string_literal: true

module Sevgi
  module Geometry
    # Closed three-sided element built from two adjacent segments.
    class Triangle < Element.lined(3)
      # Builds a triangle from two adjacent segments.
      # @param segment_a [Sevgi::Geometry::Segment, Array<Numeric>] first segment
      # @param segment_b [Sevgi::Geometry::Segment, Array<Numeric>] second segment
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Triangle]
      # @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
      def self.[](segment_a, segment_b, position: Origin)
        a, b = Tuples[Segment, segment_a, segment_b]

        new_by_segments(a, b, closing_segment(a, b), position:)
      end

      def self.closing_segment(a, b)
        b_reverse_angle = b.angle - 180.0
        angle_between = b_reverse_angle - a.angle
        length = closing_length(a, b, angle_between)

        Segment[length, closing_angle(a, b_reverse_angle, angle_between, length)]
      end

      def self.closing_angle(a, b_reverse_angle, angle_between, length)
        b_reverse_angle + F.asin(a.length * F.sin(angle_between) / length)
      end

      def self.closing_length(a, b, angle_between)
        ::Math.sqrt((a.length ** 2) + (b.length ** 2) - (2 * a.length * b.length * F.cos(angle_between)))
      end

      private_class_method :closing_angle, :closing_length, :closing_segment
    end
  end
end
