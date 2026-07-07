# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Rect.
    # @api private
    RectBase = Element.lined(4)
    private_constant :RectBase

    # Closed four-sided rectangle aligned to the screen axes.
    class Rect < RectBase
      # @overload [](width, height, position: Origin)
      #   Builds a rectangle from size and top-left position.
      #   @param width [Numeric] rectangle width
      #   @param height [Numeric] rectangle height
      #   @param position [Sevgi::Geometry::Point, Array<Numeric>] top-left position
      #   @return [Sevgi::Geometry::Rect]
      #   @raise [Sevgi::Geometry::Error] when position cannot be coerced
      def self.[](...) = from_size(...)

      # @overload call(top_left, bottom_right)
      #   Builds a rectangle from two opposite corners.
      #   @param top_left [Sevgi::Geometry::Point, Array<Numeric>] top-left corner
      #   @param bottom_right [Sevgi::Geometry::Point, Array<Numeric>] bottom-right corner
      #   @return [Sevgi::Geometry::Rect]
      #   @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      def self.call(...) = from_corners(...)

      # Builds a rectangle from two opposite corners.
      # @param top_left [Sevgi::Geometry::Point, Array<Numeric>] top-left corner
      # @param bottom_right [Sevgi::Geometry::Point, Array<Numeric>] bottom-right corner
      # @return [Sevgi::Geometry::Rect]
      # @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      def self.from_corners(top_left, bottom_right)
        top_left, bottom_right = Tuples[Point, top_left, bottom_right]
        width = (bottom_right.x - top_left.x).abs

        new_by_points(
          top_left,
          top_left.translate(width, 0.0),
          bottom_right,
          bottom_right.translate(-width, 0.0)
        )
      end

      # Builds a rectangle from size and top-left position.
      # @param width [Numeric] rectangle width
      # @param height [Numeric] rectangle height
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] top-left position
      # @return [Sevgi::Geometry::Rect]
      # @raise [Sevgi::Geometry::Error] when position cannot be coerced
      def self.from_size(width, height, position: Origin)
        new_by_segments(
          Segment.rightward(width),
          Segment.downward(height),
          Segment.leftward(width),
          Segment.upward(height),
          position:
        )
      end

      # Draws the rectangle into a graphics node.
      # @param node [Object] graphics node receiving the drawing command
      # @return [Object] graphics node command result
      def draw!(node, **) = node.rect(x: position.x, y: position.y, width: width, height: height, **)

      # Returns rectangle height.
      # @return [Float]
      def height = @height ||= segments[1].length

      # Returns rectangle width.
      # @return [Float]
      def width = @width ||= segments[0].length

      %i[top_left top_right bottom_right bottom_left].each_with_index do |corner, i|
        define_method(corner) { points[i] }
      end

      %i[top right bottom left].each_with_index do |side, i|
        define_method(side) { lines[i] }
      end
    end

    # Rectangle with equal width and height.
    class Square < Rect
      # @return [Float] side length
      alias length width

      # Builds a square from side length and top-left position.
      # @param length [Numeric] side length
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] top-left position
      # @return [Sevgi::Geometry::Square]
      # @raise [Sevgi::Geometry::Error] when position cannot be coerced
      def self.[](length, position: Origin) = from_size(length, length, position:)
    end
  end
end
