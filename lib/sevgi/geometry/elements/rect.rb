# frozen_string_literal: true

# codebeat:disable[TOO_MANY_IVARS]

require "forwardable"

module Sevgi
  module Geometry
    class Rect < Element
      # Argument order is in clockwise rotation from position point
      Corner = Data.define(:top_left, :top_right, :bottom_right, :bottom_left) do
        class << self
          def of(rect)
            position = rect.position

            new(
              top_left:     position,
              top_right:    position.translate(dx: rect.width),
              bottom_right: position.translate(dx: rect.width, dy: rect.height),
              bottom_left:  position.translate(dy: rect.height)
            )
          end
        end
      end

      # Argument order is in clockwise rotation from top segment (as in CSS)
      Side = Data.define(:top, :right, :bottom, :left) do
        class << self
          def of(rect)
            corner = rect.corner

            new(
              top:    Segment[corner.top_left,    corner.top_right],
              right:  Segment[corner.top_right,   corner.bottom_right],
              bottom: Segment[corner.bottom_left, corner.bottom_right],
              left:   Segment[corner.top_left,    corner.bottom_left]
            )
          end
        end
      end

      extend Forwardable

      def_delegators :@side,   *Side.members
      def_delegators :@corner, *Corner.members

      attr_reader :position, :width, :height
      attr_reader :corner, :corners, :side, :sides

      def initialize(position: nil, width:, height:)
        super()

        @position = position || Point.origin
        @width    = width.to_f
        @height   = height.to_f

        compute
      end

      def bbox
        BBox[*@corner.deconstruct]
      end

      def diagonal
        Segment.forward(top_left, bottom_right)
      end

      def draw(container, **)
        container.rect(x: position.x, y: position.y, width: width, height: height, **)
      end

      def inside?(point)
        onto?(point) || (left.right?(point) && right.left?(point) && top.left?(point) && bottom.right?(point))
      end

      # codebeat:disable[ABC]
      def intersection(line, precision: nil)
        points = sides.map { _1.intersection(line).approx(precision) }.uniq.select { onto?(_1) }
        return if points.empty?

        GeometryError.("Unexpected number of intersection points: #{points.size}") if points.size > 2

        Segment.forward(*points)
      end
      # codebeat:enable[ABC]

      def onto?(point)
        left.onto?(point) || right.onto?(point) || top.onto?(point) || bottom.onto?(point)
      end

      def orient(new_orientation)
        return self if orientation == new_orientation

        with(width: height, height: width)
      end

      def orientation
        F.gt?(width, height) ? :landscape : :portrait
      end

      def outside?(point)
        !inside?(point)
      end

      def to_s
        strings = []

        strings << "R[#{F.approx(width)}x#{F.approx(height)}]"
        strings << position.to_s if Point.eq?(position, Point.origin)

        strings.join("@")
      end

      def translate(dx: nil, dy: nil)
        self.class.new(position: position.translate(dx:, dy:), width: width, height: height)
      end

      private

      def compute
        @corner   = Corner.of(self)
        @corners  = Corner.members.map { public_send(_1) }

        @side     = Side.of(self)
        @sides    = Side.members.map { public_send(_1) }
      end

      class << self
        def [](width, height) = new(width:, height:)
      end
    end
  end
end
