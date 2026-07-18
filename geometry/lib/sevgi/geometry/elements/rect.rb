# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Rect.
    # @api private
    RectBase = Element.lined(4)
    private_constant :RectBase

    # Closed four-sided rectangle aligned to the screen axes. Affine operations return Rect while the result remains
    # axis-aligned and widen to {Parallelogram} after rotation or skew changes that category. A Square similarly widens
    # to Rect after unequal scaling.
    # @example Inspect corners, sides, and containment
    #   rect = Sevgi::Geometry::Rect[8, 4, position: [2, 3]]
    #   rect.top_left.deconstruct # => [2.0, 3.0]
    #   rect.right.length         # => 4.0
    #   rect.inside?([5, 5])      # => true
    # @example Observe semantic widening after affine transforms
    #   Sevgi::Geometry::Rect[8, 4].rotate(30).class # => Sevgi::Geometry::Parallelogram
    #   Sevgi::Geometry::Square[4].scale(2, 1).class # => Sevgi::Geometry::Rect
    # @!attribute [r] A
    #   @return [Sevgi::Geometry::Point] top-left vertex
    # @!attribute [r] B
    #   @return [Sevgi::Geometry::Point] top-right vertex
    # @!attribute [r] C
    #   @return [Sevgi::Geometry::Point] bottom-right vertex
    # @!attribute [r] D
    #   @return [Sevgi::Geometry::Point] bottom-left vertex
    # @!attribute [r] AB
    #   @return [Sevgi::Geometry::Line] top side
    # @!attribute [r] BC
    #   @return [Sevgi::Geometry::Line] right side
    # @!attribute [r] CD
    #   @return [Sevgi::Geometry::Line] bottom side
    # @!attribute [r] DA
    #   @return [Sevgi::Geometry::Line] left side
    # @!method perimeter
    #   Returns the closed path perimeter.
    #   @return [Float]
    class Rect < RectBase
      # @overload [](width, height, position: Origin)
      #   Builds a rectangle from size and top-left position.
      #   @param width [Numeric] rectangle width
      #   @param height [Numeric] rectangle height
      #   @param position [Sevgi::Geometry::Point, Array<Numeric>] top-left position
      #   @return [Sevgi::Geometry::Rect]
      #   @raise [Sevgi::Geometry::Error] when position cannot be coerced or a dimension is negative
      # @example Mathematical notation and English convenience are equivalent
      #   Sevgi::Geometry::Rect[3, 4] == Sevgi::Geometry::Rect.from_size(3, 4)
      def self.[](width, height, position: Origin) = construct(width, height, position:)

      # Constructs a rectangle for canonical size notation.
      # @param width [Numeric] rectangle width
      # @param height [Numeric] rectangle height
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] top-left position
      # @return [Sevgi::Geometry::Rect]
      # @raise [Sevgi::Geometry::Error] when position or a dimension is invalid
      # @api private
      def self.construct(width, height, position:)
        width = dimension!(:width, width)
        height = dimension!(:height, height)

        new_by_segments(
          Segment.rightward(width),
          Segment.downward(height),
          Segment.leftward(width),
          Segment.upward(height),
          position:
        )
      end

      # @overload call(top_left, bottom_right)
      #   Builds a rectangle from two opposite corners.
      #   @param top_left [Sevgi::Geometry::Point, Array<Numeric>] top-left corner
      #   @param bottom_right [Sevgi::Geometry::Point, Array<Numeric>] bottom-right corner
      #   @return [Sevgi::Geometry::Rect]
      #   @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      # @example Mathematical notation and English convenience are equivalent
      #   Sevgi::Geometry::Rect.([0, 0], [3, 4]) == Sevgi::Geometry::Rect.from_corners([0, 0], [3, 4])
      def self.call(top_left, bottom_right)
        top_left, bottom_right = Tuples[Point, top_left, bottom_right]
        left, right = [top_left.x, bottom_right.x].minmax
        top, bottom = [top_left.y, bottom_right.y].minmax
        width, height = right - left, bottom - top

        if self <= Square
          Error.("Square corners must define equal dimensions") unless F.eq?(width, height)

          return self[width, position: [left, top]]
        end

        self[width, height, position: [left, top]]
      end

      # Builds a rectangle from two opposite corners.
      # @param top_left [Sevgi::Geometry::Point, Array<Numeric>] top-left corner
      # @param bottom_right [Sevgi::Geometry::Point, Array<Numeric>] bottom-right corner
      # @return [Sevgi::Geometry::Rect]
      # @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      def self.from_corners(top_left, bottom_right) = call(top_left, bottom_right)

      # Builds a rectangle from size and top-left position.
      # @param width [Numeric] rectangle width
      # @param height [Numeric] rectangle height
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] top-left position
      # @return [Sevgi::Geometry::Rect]
      # @raise [Sevgi::Geometry::Error] when position cannot be coerced or a dimension is negative
      def self.from_size(width, height, position: Origin) = self[width, height, position:]

      class << self
        private

        def affine(*points)
          left, right, top, bottom = bounds(points)
          width, height = right - left, bottom - top

          unless axis_aligned?(points, left, right, top, bottom)
            return Parallelogram.call(*points.first(4))
          end

          klass = self <= Square && F.eq?(width, height) ? Square : Rect
          return klass[width, position: [left, top]] if klass == Square

          klass[width, height, position: [left, top]]
        end

        def approximate(*points)
          new_by_points!(*points)
        rescue Error
          return Rect.send(:new_by_points!, *points) if self <= Square

          super
        end

        def axis_aligned?(points, left, right, top, bottom)
          expected = [[left, top], [right, top], [right, bottom], [left, bottom]]
          vertices = points.first(4)

          expected.all? { |corner| vertices.any? { it.eq?(Point[*corner]) } }
        end

        def bounds(points)
          vertices = points.first(4)
          [vertices.map(&:x).min, vertices.map(&:x).max, vertices.map(&:y).min, vertices.map(&:y).max]
        end

        def dimension!(name, value)
          value = Real[name, value]
          Error.("Rectangle #{name} cannot be negative") if value.negative?

          value
        end
      end

      private_class_method :construct, :from_points, :from_segments

      # Draws the rectangle into a graphics node.
      # @param node [Object] graphics node receiving the drawing command
      # @return [Object] graphics node command result
      def draw!(node, **) = node.rect(x: position.x, y: position.y, width: width, height: height, **)

      private :draw!

      # Returns rectangle height.
      # @return [Float]
      def height = @height ||= segments[1].length

      # Returns rectangle width.
      # @return [Float]
      def width = @width ||= segments[0].length

      # @!parse
      #   # Returns the top-left corner.
      #   # @return [Sevgi::Geometry::Point]
      #   def top_left; end
      #
      #   # Returns the top-right corner.
      #   # @return [Sevgi::Geometry::Point]
      #   def top_right; end
      #
      #   # Returns the bottom-right corner.
      #   # @return [Sevgi::Geometry::Point]
      #   def bottom_right; end
      #
      #   # Returns the bottom-left corner.
      #   # @return [Sevgi::Geometry::Point]
      #   def bottom_left; end
      %i[top_left top_right bottom_right bottom_left].each_with_index do |corner, i|
        define_method(corner) { points[i] }
      end

      # @!parse
      #   # Returns the top side line.
      #   # @return [Sevgi::Geometry::Line]
      #   def top; end
      #
      #   # Returns the right side line.
      #   # @return [Sevgi::Geometry::Line]
      #   def right; end
      #
      #   # Returns the bottom side line.
      #   # @return [Sevgi::Geometry::Line]
      #   def bottom; end
      #
      #   # Returns the left side line.
      #   # @return [Sevgi::Geometry::Line]
      #   def left; end
      %i[top right bottom left].each_with_index do |side, i|
        define_method(side) { lines[i] }
      end

      private

      def validate_geometry!
        left, right, top, bottom = self.class.send(:bounds, points)
        expected = [[left, top], [right, top], [right, bottom], [left, bottom], [left, top]]
        valid = points.zip(expected).all? { |point, pair| point.eq?(Point[*pair]) }

        Error.("Rectangle points must form an axis-aligned rectangle") unless valid
      end
    end

    # Rectangle with equal width and height. Use {#width} or {#height} for its side length; inherited
    # {Element::Lined#length} returns the complete path length.
    # @example Construct the same square from opposite corners
    #   Sevgi::Geometry::Square.([0, 0], [5, 5]) == Sevgi::Geometry::Square.from_corners([0, 0], [5, 5])
    class Square < Rect
      # Builds a square from side length and top-left position.
      # @param length [Numeric] side length
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] top-left position
      # @return [Sevgi::Geometry::Square]
      # @raise [Sevgi::Geometry::Error] when position cannot be coerced or length is negative
      # @example Mathematical notation and English convenience are equivalent
      #   Sevgi::Geometry::Square[5] == Sevgi::Geometry::Square.from_size(5)
      def self.[](length, position: Origin) = construct(length, length, position:)

      # Builds a square from two opposite corners.
      # @param top_left [Sevgi::Geometry::Point, Array<Numeric>] top-left corner
      # @param bottom_right [Sevgi::Geometry::Point, Array<Numeric>] bottom-right corner
      # @return [Sevgi::Geometry::Square]
      # @raise [Sevgi::Geometry::Error] when points are invalid or define unequal dimensions
      def self.from_corners(top_left, bottom_right) = call(top_left, bottom_right)

      # Builds a square from side length and top-left position.
      # @param length [Numeric] side length
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] top-left position
      # @return [Sevgi::Geometry::Square]
      # @raise [Sevgi::Geometry::Error] when position or length is invalid
      def self.from_size(length, position: Origin) = self[length, position:]

      private

      def validate_geometry!
        super
        Error.("Square sides must have equal length") unless F.eq?(width, height)
      end
    end
  end
end
