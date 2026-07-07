# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Geometry
    class Line < Element.lined(1, open: true)
      def self.[](...) = from_length_angle(...)

      def self.from_length_angle(length, angle, position: Origin) = new_by_segments(Segment[length, angle], position:)

      def self.from_points(...) = new_by_points(...)

      extend Forwardable

      def_delegators :head, :length, :angle

      def_delegator :points, :first, :starting
      def_delegator :points, :last, :ending

      def_delegators :equation, :left?, :right?

      def draw!(node, **) = node.LineTo(x1: position.x, y1: position.y, x2: ending.x, y2: ending.y, **)

      def over?(point)
        point = Tuple[Point, point]

        within_range?(point) && equation.on?(point)
      end

      def shift(distance) = translate(distance * F.sin(angle), -distance * F.cos(angle))

      private

      def within_range?(point)
        return false if point.nan?

        point = point.approx
        points = [starting.approx, ending.approx]

        point.between?(points.min, points.max)
      end
    end
  end
end
