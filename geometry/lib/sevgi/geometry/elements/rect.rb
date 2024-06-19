# frozen_string_literal: true

module Sevgi
  module Geometry
    class Rect < Element.lined(4)
      def self.call(top_left, bottom_right)
        top_left, bottom_right = Tuples[Point, top_left, bottom_right]
        width = (bottom_right.x - top_left.x).abs

        new_by_points(
          top_left,
          top_left.translate(width, 0.0),
          bottom_right,
          bottom_right.translate(-width, 0.0)
        )
      end

      def self.[](width, height, position: Origin)
        new_by_segments(
          Segment.horizontal(width),
          Segment.vertical(height),
          Segment.horizontal!(width),
          Segment.vertical!(height),
          position:
        )
      end

      def draw!(node, **) = node.rect(x: position.x, y: position.y, width: width, height: height, **)

      def height          = @height ||= segments[1].length

      def width           = @width  ||= segments[0].length

      %i[top_left top_right bottom_right bottom_left].each_with_index do |corner, i|
        define_method(corner) { points[i] }
      end

      %i[top right bottom left].each_with_index do |side, i|
        define_method(side) { lines[i] }
      end
    end

    class Square < Rect
      alias_method :length, :width

      def self.[](length, position: Origin) = super(length, length, position:)
    end
  end
end
