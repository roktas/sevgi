# frozen_string_literal: true

module Sevgi
  module Geometry
    class Parallelogram < Element.lined(4)
      def self.[](horizontal, vertical, position: Origin)
        horizontal, vertical = Tuples[Segment, horizontal, vertical]

        new_by_segments(horizontal, vertical.reverse, horizontal.reverse, vertical, position:)
      end

      def self.new_by_height(horizontal:, tallness:, position: Origin)
        horizontal = Tuple[Segment, horizontal]
        tallness = Tuple[Polar, tallness]

        height = tallness.length - horizontal.y.abs
        angle = tallness.angle
        length = height / F.sin(angle)

        self[horizontal, Segment[length, angle], position:]
      end

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
