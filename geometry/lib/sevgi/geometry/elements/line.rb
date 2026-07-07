# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Geometry
    # Generated superclass for Line.
    # @api private
    LineBase = Element.lined(1, open: true)
    private_constant :LineBase

    # Open lined element with one segment.
    class Line < LineBase
      # @overload [](length, angle, position: Origin)
      #   Builds a line from length and angle.
      #   @param length [Numeric] line length
      #   @param angle [Numeric] clockwise angle in degrees
      #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      #   @return [Sevgi::Geometry::Line]
      #   @raise [Sevgi::Geometry::Error] when position cannot be coerced
      def self.[](...) = from_length_angle(...)

      # Builds a line from length and angle.
      # @param length [Numeric] line length
      # @param angle [Numeric] clockwise angle in degrees
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Line]
      # @raise [Sevgi::Geometry::Error] when position cannot be coerced
      def self.from_length_angle(length, angle, position: Origin) = new_by_segments(Segment[length, angle], position:)

      # @overload from_points(starting, ending)
      #   Builds a line from two endpoints.
      #   @param starting [Sevgi::Geometry::Point, Array<Numeric>] starting point
      #   @param ending [Sevgi::Geometry::Point, Array<Numeric>] ending point
      #   @return [Sevgi::Geometry::Line]
      #   @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      def self.from_points(...) = new_by_points(...)

      extend Forwardable

      def_delegators :head, :length, :angle

      def_delegator :points, :first, :starting
      def_delegator :points, :last, :ending

      def_delegators :equation, :left?, :right?

      # Draws the line into a graphics node.
      # @param node [Object] graphics node receiving the drawing command
      # @return [Object] graphics node command result
      def draw!(node, **) = node.LineTo(x1: position.x, y1: position.y, x2: ending.x, y2: ending.y, **)

      # Reports whether a point lies on the finite line segment.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def over?(point)
        point = Tuple[Point, point]

        within_range?(point) && equation.on?(point)
      end

      # Returns a parallel line shifted by a signed perpendicular offset.
      # @param distance [Numeric] signed perpendicular offset
      # @return [Sevgi::Geometry::Line]
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
