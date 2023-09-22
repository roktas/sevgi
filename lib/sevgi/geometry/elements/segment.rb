# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Geometry
    class Segment < Element
      extend Forwardable

      def_delegators :line, :left?, :right?, :intersection

      attr_reader :position, :ending

      def initialize(position: Point.origin, ending:, &block)
        super()

        @position = position
        @ending   = ending

        instance_exec(&block) if block # optimization backdoor for constructors
      end

      def bbox
        BBox[position, ending]
      end

      def direction
        @direction ||= F.angler(dx, dy)
      end

      def dx
        @dx ||= F.dxp(position, ending)
      end

      def dy
        @dy ||= F.dyp(position, ending)
      end

      def draw(container, **)
        container.segment(x1: position.x, y1: position.y, x2: ending.x, y2: ending.y, **)
      end

      def horizontal?(precision = nil)
        F.horizontal?(direction, precision:)
      end

      def infinite?
        [position, ending].any(&:infinite?)
      end

      def length
        @length ||= F.distance(position, ending)
      end

      def line
        @line ||= Equation::Line.from_segment(self)
      end

      def onto?(point)
        point.unordered_between?(ending, position) && line.onto?(point)
      end

      def rect
        @rect ||= Rect[dx.abs, dy.abs]
      end

      def to_s
        "S[#{position} -> #{ending}]"
      end

      def translate(dx: nil, dy: nil)
        self.class.new(position: position.translate(dx:, dy:), ending: ending.translate(dx:, dy:))
      end

      def vertical?(precision = nil)
        F.vertical?(direction, precision:)
      end

      class << self
        def [](position, ending)
          new(position:, ending:)
        end

        def forward(p, q = nil)
          new(position: (points = [p, q || p]).sort!.shift, ending: points.shift)
        end

        def directed(position: Point.origin, length:, direction:)
          dx = F.dxa(length, direction)
          dy = F.dya(length, direction)

          new(position: position, ending: position.translate(dx:, dy:)) do # avoid recalculations
            @direction = direction.to_f
            @length    = length.to_f
            @dx        = dx
            @dy        = dy
          end
        end
      end
    end
  end
end
