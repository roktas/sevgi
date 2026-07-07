# frozen_string_literal: true

require "delegate"

module Sevgi
  module Sundries
    # Builds a tile-like grid from horizontal and vertical rulers.
    class Grid < Tile
      # Builds a grid using bracket syntax.
      # @param x [Sevgi::Sundries::Ruler] horizontal ruler
      # @param y [Sevgi::Sundries::Ruler] vertical ruler
      # @return [Sevgi::Sundries::Grid]
      # @raise [Sevgi::ArgumentError] when either argument is not a ruler
      def self.[](x, y) = new(x:, y:)

      # @!attribute [r] x
      #   @return [Sevgi::Sundries::Grid::X] horizontal axis ruler and line queries
      # @!attribute [r] y
      #   @return [Sevgi::Sundries::Grid::Y] vertical axis ruler and line queries
      attr_reader :x, :y

      # Creates a grid from horizontal and vertical rulers.
      # @param x [Sevgi::Sundries::Ruler] horizontal ruler
      # @param y [Sevgi::Sundries::Ruler] vertical ruler
      # @return [void]
      # @raise [Sevgi::ArgumentError] when either argument is not a ruler
      def initialize(x:, y:)
        ArgumentError.("Arguments must be Ruler objects") unless [x, y].all?(Ruler)

        @x = X.new(x, y)
        @y = Y.new(x, y)

        super(Geometry::Rect[@x.u, @y.u], nx: @x.n, ny: @y.n)
      end

      # Returns a graphics canvas matching the rulers and computed margins.
      # @return [Sevgi::Graphics::Canvas]
      def canvas
        Graphics::Canvas.new(
          **Graphics::Paper[x.brut, y.brut].to_h,
          margins: Graphics::Margin[y.margin, x.margin].to_a
        )
      end

      # Returns the fitted grid height.
      # @return [Float]
      def height = y.d

      # Returns the fitted grid width.
      # @return [Float]
      def width = x.d

      # Axis wrapper exposing grid line queries for one ruler direction.
      # @api private
      class Axis < DelegateClass(Ruler)
        # Returns the major line query.
        # @return [Sevgi::Sundries::Grid::Axis::Major]
        attr_reader :major

        # Returns the midpoint line query.
        # @return [Sevgi::Sundries::Grid::Axis::Halve]
        attr_reader :halve

        # Returns the minor line query.
        # @return [Sevgi::Sundries::Grid::Axis::Minor]
        attr_reader :minor

        # Creates an axis wrapper.
        # @param this [Sevgi::Sundries::Ruler] ruler represented by this axis
        # @param other [Sevgi::Sundries::Ruler] ruler used for perpendicular tick locations
        # @return [void]
        def initialize(this, other)
          super(this)

          @major = Major.new(self, other)
          @halve = Halve.new(self, other)
          @minor = Minor.new(self, other)
        end

        # Memoized grid line query for an axis.
        # @api private
        class Query
          # Creates a query.
          # @param this [Sevgi::Sundries::Grid::Axis] axis receiving generated lines
          # @param other [Sevgi::Sundries::Ruler] perpendicular ruler supplying tick distances
          # @return [void]
          def initialize(this, other) = (@this, @other = this, other)

          # Returns grid line endpoints as coordinate pairs.
          # @return [Array<Array<Array<Float>>>]
          def xys = @xys ||= lines.map { it.points(true).map(&:deconstruct) }

          # Returns grid line endpoints as points.
          # @return [Array<Array<Sevgi::Geometry::Point>>]
          def points = @points ||= lines.map { it.points(true) }

          # Returns generated grid lines.
          # @return [Array<Sevgi::Geometry::Line>]
          def lines = @lines ||= lines!

          private

          attr_reader :this, :other
        end

        # Major grid line query.
        # @api private
        class Major < Query
          # Returns lines at major tick distances.
          # @return [Array<Sevgi::Geometry::Line>]
          def lines! = other.ds.map { this.line_at(it) }
        end

        # Midpoint grid line query.
        # @api private
        class Halve < Query
          # Returns lines at midpoint tick distances.
          # @return [Array<Sevgi::Geometry::Line>]
          def lines! = other.hs.map { this.line_at(it) }
        end

        # Minor grid line query.
        # @api private
        class Minor < Query
          # Returns lines at minor tick distances.
          # @return [Array<Sevgi::Geometry::Line>]
          def lines! = other.ms.map { this.line_at(it) }
        end
      end

      # Horizontal grid axis.
      # @api private
      class X < Axis
        # Returns the base horizontal line for this axis.
        # @return [Sevgi::Geometry::Line]
        def line = @line ||= Geometry::Line[d, 0.0]

        # Returns a horizontal line translated to a y coordinate.
        # @param y [Numeric] y coordinate
        # @return [Sevgi::Geometry::Line]
        def line_at(y) = line.at([0.0, y])
      end

      # Vertical grid axis.
      # @api private
      class Y < Axis
        # Creates a vertical axis wrapper.
        # @param this [Sevgi::Sundries::Ruler] horizontal ruler
        # @param other [Sevgi::Sundries::Ruler] vertical ruler
        # @return [void]
        def initialize(this, other) = super(other, this)

        # Returns the base vertical line for this axis.
        # @return [Sevgi::Geometry::Line]
        def line = @line ||= Geometry::Line[d, 90.0]

        # Returns a vertical line translated to an x coordinate.
        # @param x [Numeric] x coordinate
        # @return [Sevgi::Geometry::Line]
        def line_at(x) = line.at([x, 0.0])
      end
    end
  end
end
