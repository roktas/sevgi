# frozen_string_literal: true

require "delegate"

module Sevgi
  module Sundries
    class Grid < Tile
      def self.[](x, y) = new(x:, y:)

      attr_reader :x, :y

      def initialize(x:, y:)
        ArgumentError.("Arguments must be Ruler objects") unless [ x, y ].all? { it.is_a?(Ruler) }

        @x = X.new(x, y)
        @y = Y.new(x, y)

        super(Geometry::Rect[@x.u, @y.u], nx: @x.n, ny: @y.n)
      end

      def canvas = Graphics::Canvas.new(**Graphics::Paper[x.brut, y.brut].to_h, margins: Graphics::Margin[y.margin, x.margin].to_a)

      def height = y.d

      def width  = x.d

      class Axis < DelegateClass(Ruler)
        attr_reader :major, :halve, :minor

        def initialize(this, other)
          super(this)

          @major = Major.new(self, other)
          @halve = Halve.new(self, other)
          @minor = Minor.new(self, other)
        end

        class Query
          def initialize(this, other) = (@this, @other = this, other)

          def xys    = @xys    ||= lines.map { it.points(true).map(&:deconstruct) }

          def points = @points ||= lines.map { it.points(true) }

          def lines  = @lines  ||= lines!

          private

            attr_reader :this, :other
        end

        class Major < Query
          def lines! = other.ds.map { this.line.shift(it) }
        end

        class Halve < Query
          def lines! = other.hs.map { this.line.shift(it) }
        end

        class Minor < Query
          def lines! = other.ms.map { this.line.shift(it) }
        end
      end

      class X < Axis
        def line = @line ||= Geometry::Line[d, 0.0]
      end

      class Y < Axis
        def initialize(this, other) = super(other, this)

        def line                    = @line || Geometry::Line[d, 90.0]
      end
    end
  end
end
