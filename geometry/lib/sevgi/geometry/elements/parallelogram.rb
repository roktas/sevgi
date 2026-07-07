# frozen_string_literal: true

module Sevgi
  module Geometry
    # Closed four-sided element built from horizontal and vertical segments.
    class Parallelogram < Element.lined(4)
      # Builds a parallelogram from adjacent horizontal and vertical segments.
      # @param horizontal [Sevgi::Geometry::Segment, Array<Numeric>] horizontal segment
      # @param vertical [Sevgi::Geometry::Segment, Array<Numeric>] vertical segment
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
      def self.[](horizontal, vertical, position: Origin)
        horizontal, vertical = Tuples[Segment, horizontal, vertical]

        new_by_segments(horizontal, vertical.reverse, horizontal.reverse, vertical, position:)
      end

      # Builds a parallelogram from a horizontal segment and tallness constraint.
      # @param horizontal [Sevgi::Geometry::Segment, Array<Numeric>] horizontal segment
      # @param tallness [Sevgi::Geometry::Polar, Array<Numeric>] target tallness as length and angle
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when inputs cannot be coerced
      def self.new_by_height(horizontal:, tallness:, position: Origin)
        horizontal = Tuple[Segment, horizontal]
        tallness = Tuple[Polar, tallness]

        height = tallness.length - horizontal.y.abs
        angle = tallness.angle
        length = height / F.sin(angle)

        self[horizontal, Segment[length, angle], position:]
      end

      # Builds a parallelogram from a vertical segment and wideness constraint.
      # @param vertical [Sevgi::Geometry::Segment, Array<Numeric>] vertical segment
      # @param wideness [Sevgi::Geometry::Polar, Array<Numeric>] target wideness as length and angle
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when inputs cannot be coerced
      def self.new_by_width(vertical:, wideness:, position: Origin)
        vertical = Tuple[Segment, vertical]
        wideness = Tuple[Polar, wideness]

        width = wideness.length - vertical.x.abs
        angle = wideness.angle
        length = width / F.cos(angle)

        self[Segment[length, angle], vertical, position:]
      end
    end
  end
end
