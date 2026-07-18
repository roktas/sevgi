# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Line.
    # @api private
    LineBase = Element.lined(1, open: true)
    private_constant :LineBase

    # Finite, directed line between two endpoints.
    #
    # Direction affects {#left?}, {#right?}, and the sign of {#shift}. Use
    # {#equation} when the corresponding infinite line is required; {#over?}
    # deliberately tests only the finite extent between the endpoints.
    # @example Query sides of a directed line in screen coordinates
    #   line = Sevgi::Geometry::Line.([0, 0], [10, 0])
    #   line.left?([5, -2])  # => true
    #   line.right?([5, 2])  # => true
    #   line.shift(2).starting.deconstruct # => [0.0, -2.0]
    # @example Distinguish the finite segment from its infinite equation
    #   line = Sevgi::Geometry::Line.([0, 0], [10, 0])
    #   line.over?([5, 0])  # => true
    #   line.over?([15, 0]) # => false
    # @!method self.call(starting, ending)
    #   Builds a line from two endpoints.
    #   @param starting [Sevgi::Geometry::Point, Array<Numeric>] starting point
    #   @param ending [Sevgi::Geometry::Point, Array<Numeric>] ending point
    #   @return [Sevgi::Geometry::Line]
    #   @raise [Sevgi::Geometry::Error] when either point cannot be coerced
    # @!attribute [r] A
    #   @return [Sevgi::Geometry::Point] starting point
    # @!attribute [r] B
    #   @return [Sevgi::Geometry::Point] ending point
    # @!attribute [r] AB
    #   @return [Sevgi::Geometry::Line] line from A to B
    class Line < LineBase
      # @overload [](length, angle, position: Origin)
      #   Builds a line from length and angle.
      #   @param length [Numeric] line length
      #   @param angle [Numeric] clockwise angle in degrees
      #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      #   @return [Sevgi::Geometry::Line]
      #   @raise [Sevgi::Geometry::Error] when length, angle, or position cannot be coerced to finite geometry values
      # @example Mathematical notation and English convenience are equivalent
      #   Sevgi::Geometry::Line[5, 30] == Sevgi::Geometry::Line.from_length_angle(5, 30)
      def self.[](length, angle, position: Origin) = new_by_segments(Segment[length, angle], position:)

      # Builds a line from length and angle.
      # @param length [Numeric] line length
      # @param angle [Numeric] clockwise angle in degrees
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Line]
      # @raise [Sevgi::Geometry::Error] when length, angle, or position cannot be coerced to finite geometry values
      def self.from_length_angle(length, angle, position: Origin) = self[length, angle, position:]

      # @overload from_points(starting, ending)
      #   Builds a line from two endpoints.
      #   @param starting [Sevgi::Geometry::Point, Array<Numeric>] starting point
      #   @param ending [Sevgi::Geometry::Point, Array<Numeric>] ending point
      #   @return [Sevgi::Geometry::Line]
      #   @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      # @example Mathematical notation and English convenience are equivalent
      #   Sevgi::Geometry::Line.([0, 0], [3, 4]) == Sevgi::Geometry::Line.from_points([0, 0], [3, 4])
      def self.from_points(...) = call(...)

      private_class_method :from_segments

      # Returns the clockwise line angle in degrees.
      # @return [Float]
      def angle = head.angle

      # Returns the ending point.
      # @return [Sevgi::Geometry::Point]
      def ending = points.last

      # Reports whether a point is left of the directed line from {#starting} to {#ending} in screen coordinates.
      # Points on the infinite line are on neither side. A zero-length line has no direction and returns false.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def left?(point) = F.lt?(side(point), 0.0)

      # Reports whether a point is right of the directed line from {#starting} to {#ending} in screen coordinates.
      # Points on the infinite line are on neither side. A zero-length line has no direction and returns false.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def right?(point) = F.gt?(side(point), 0.0)

      # Returns the starting point.
      # @return [Sevgi::Geometry::Point]
      def starting = points.first

      # Draws the line into a graphics node.
      # @param node [Object] graphics node receiving the drawing command
      # @return [Object] graphics node command result
      def draw!(node, **) = node.LineTo(x1: position.x, y1: position.y, x2: ending.x, y2: ending.y, **)

      private :draw!

      # Reports whether a point lies on the finite line segment.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def over?(point)
        point = Tuple[Point, point]

        within_range?(point) && equation.on?(point)
      end

      # Returns a parallel line shifted by a signed perpendicular offset.
      # Positive distance moves to the directed line's left in screen coordinates; reversing the endpoints reverses the
      # shift direction.
      # @param distance [Numeric] signed perpendicular offset
      # @return [Sevgi::Geometry::Line]
      # @raise [Sevgi::Geometry::Error] when distance is not a finite real number
      def shift(distance)
        distance = Real[:distance, distance]
        translate(distance * F.sin(angle), -distance * F.cos(angle))
      end

      private

      def cross(ax, ay, bx, by) = (ax * by) - (ay * bx)
      def delta(from, to) = [to.x - from.x, to.y - from.y]

      def side(point)
        point = Tuple[Point, point]
        cross(*delta(starting, ending), *delta(starting, point))
      end

      def within_range?(point)
        point = point.approx
        points = [starting.approx, ending.approx]

        point.between?(points.min, points.max)
      end
    end
  end
end
