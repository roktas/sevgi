# frozen_string_literal: true

require "delegate"

module Sevgi
  module Sundries
    # Builds a tile-like grid from horizontal and vertical rulers.
    #
    # Axis names describe line direction, not the coordinate used to place a
    # line: `grid.x` produces horizontal lines whose y positions come from the
    # vertical ruler; `grid.y` produces vertical lines whose x positions come
    # from the horizontal ruler. Each query can return geometry lines, Point
    # endpoint pairs, or plain coordinate pairs for different consumers.
    # @example Query fitted horizontal and vertical lines
    #   x = Sevgi::Sundries::Ruler.new(brut: 80, unit: 1, multiple: 10, margins: [5])
    #   y = Sevgi::Sundries::Ruler.new(brut: 50, unit: 1, multiple: 10, margins: [5])
    #   grid = Sevgi::Sundries::Grid[x, y]
    #   grid.x.major.lines.size # => 5
    #   grid.y.minor.lines.size # => 71
    # @example Preserve a source canvas while fitting axis margins
    #   canvas = Sevgi::Graphics::Canvas.call(width: 80, height: 50)
    #   x = Sevgi::Sundries::Ruler.new(brut: 80, unit: 1, multiple: 10, margins: [5, 7])
    #   y = Sevgi::Sundries::Ruler.new(brut: 50, unit: 1, multiple: 10, margins: [3, 5])
    #   grid = Sevgi::Sundries::Grid.new(x:, y:, canvas:)
    #   grid.canvas.margin.to_a # => [4.0, 11.0, 6.0, 9.0]
    # @example Use lines, points, coordinate pairs, and inherited row boxes
    #   x = Sevgi::Sundries::Ruler.new(brut: 30, unit: 1, multiple: 10)
    #   y = Sevgi::Sundries::Ruler.new(brut: 20, unit: 1, multiple: 10)
    #   grid = Sevgi::Sundries::Grid[x, y]
    #   grid.x.major.lines.size  # => 3
    #   grid.x.major.points.first.map(&:deconstruct) # => [[0.0, 0.0], [30.0, 0.0]]
    #   grid.y.halve.xys.first   # => [[5.0, 0.0], [5.0, 20.0]]
    #   grid.rowbox.approx.height # => 10.0
    # @see Sevgi::Sundries::Ruler
    # @see Sevgi::Graphics::Mixtures::Hatch
    class Grid < Tile
      # Builds a grid using bracket syntax.
      # @param x [Sevgi::Sundries::Ruler] horizontal ruler
      # @param y [Sevgi::Sundries::Ruler] vertical ruler
      # @return [Sevgi::Sundries::Grid]
      # @raise [Sevgi::ArgumentError] when either argument is not a ruler
      def self.[](x, y) = new(x:, y:)

      # Returns the horizontal-line axis and its ruler queries.
      # Line positions are supplied by the vertical ruler.
      # @return [Sevgi::Sundries::Grid::X]
      attr_reader :x

      # Returns the vertical-line axis and its ruler queries.
      # Line positions are supplied by the horizontal ruler.
      # @return [Sevgi::Sundries::Grid::Y]
      attr_reader :y

      # Creates a grid from horizontal and vertical rulers.
      # @param x [Sevgi::Sundries::Ruler] horizontal ruler
      # @param y [Sevgi::Sundries::Ruler] vertical ruler
      # @param canvas [Sevgi::Graphics::Canvas, nil] source canvas whose identity should be preserved
      # @return [void]
      # @raise [Sevgi::ArgumentError] when either argument is not a ruler
      # @raise [Sevgi::ArgumentError] when the source canvas does not match the ruler spans
      # @raise [Sevgi::ArgumentError] when either ruler fits no interval
      def initialize(x:, y:, canvas: nil)
        validate_axes(x, y)
        validate_canvas(canvas, x, y)

        @source = canvas
        @x = X.send(:new, x, y)
        @y = Y.send(:new, x, y)

        super(Geometry::Rect[@x.u, @y.u], nx: @x.n, ny: @y.n)
      end

      # Returns a graphics canvas matching the ruler spans and fitted margins.
      # Horizontal ruler margins become the canvas left/right margins; vertical
      # ruler margins become its top/bottom margins.
      # @example Build a drawing with the fitted canvas
      #   x = Sevgi::Sundries::Ruler.new(brut: 80, unit: 1, multiple: 10, margins: [5])
      #   y = Sevgi::Sundries::Ruler.new(brut: 50, unit: 1, multiple: 10, margins: [5])
      #   grid = Sevgi::Sundries::Grid[x, y]
      #   drawing = Sevgi::Graphics.SVG(:inkscape, grid.canvas) do
      #     Draw grid.x.major.lines, class: %w[guide horizontal]
      #     Draw grid.y.major.lines, class: %w[guide vertical]
      #   end
      #   drawing.Render
      # @return [Sevgi::Graphics::Canvas]
      def canvas
        margins = [y.start, x.finish, y.finish, x.start]
        return @source.with(margins:) if @source

        Graphics::Canvas.new(
          **Graphics::Paper[x.brut, y.brut].to_h,
          margins:
        )
      end

      # Returns the fitted grid height.
      # @return [Float]
      def height = y.d

      # Returns the fitted grid width.
      # @return [Float]
      def width = x.d

      # Axis wrapper exposing grid line queries for one line direction.
      class Axis < DelegateClass(Ruler)
        private_class_method :new

        # Returns lines placed at the perpendicular ruler's major distances.
        # @return [Sevgi::Sundries::Grid::Axis::Major]
        attr_reader :major

        # Returns lines placed at the perpendicular ruler's halfway distances.
        # @return [Sevgi::Sundries::Grid::Axis::Halve]
        attr_reader :halve

        # Returns lines placed at the perpendicular ruler's minor distances.
        # @return [Sevgi::Sundries::Grid::Axis::Minor]
        attr_reader :minor

        # Creates an axis wrapper.
        # @param this [Sevgi::Sundries::Ruler] ruler represented by this axis
        # @param other [Sevgi::Sundries::Ruler] ruler used for perpendicular tick locations
        # @return [void]
        # @api private
        def initialize(this, other)
          super(this)

          @major = Major.send(:new, self, other)
          @halve = Halve.send(:new, self, other)
          @minor = Minor.send(:new, self, other)
        end

        # Memoized grid line query for an axis.
        class Query
          private_class_method :new

          # Creates a query.
          # @param this [Sevgi::Sundries::Grid::Axis] axis receiving generated lines
          # @param other [Sevgi::Sundries::Ruler] perpendicular ruler supplying tick distances
          # @return [void]
          # @api private
          def initialize(this, other) = (@this, @other = this, other)

          # Returns grid line endpoints as coordinate pairs.
          # The outer and nested collections are frozen and must be treated as immutable.
          # @return [Array<Array<Array<Float>>>] frozen coordinate pairs
          def xys = @xys ||= lines.map { it.points(true).map { |point| point.deconstruct.freeze }.freeze }.freeze

          # Returns grid line endpoints as points.
          # The outer and nested collections are frozen and must be treated as immutable.
          # @return [Array<Array<Sevgi::Geometry::Point>>] frozen point pairs
          def points = @points ||= lines.map { it.points(true).freeze }.freeze

          # Returns generated grid lines.
          # The memoized collection is frozen and must be treated as immutable.
          # @return [Array<Sevgi::Geometry::Line>] frozen lines
          def lines = @lines ||= build.freeze

          private

          attr_reader :this, :other
        end

        # Major grid line query.
        class Major < Query
          private

          def build = other.ds.map { this.line_at(it) }
        end

        # Midpoint grid line query.
        class Halve < Query
          private

          def build = other.hs.map { this.line_at(it) }
        end

        # Minor grid line query.
        class Minor < Query
          private

          def build = other.ms.map { this.line_at(it) }
        end
      end

      # Horizontal grid axis.
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
      class Y < Axis
        # Creates a vertical axis wrapper.
        # @param this [Sevgi::Sundries::Ruler] horizontal ruler
        # @param other [Sevgi::Sundries::Ruler] vertical ruler
        # @return [void]
        # @api private
        def initialize(this, other) = super(other, this)

        # Returns the base vertical line for this axis.
        # @return [Sevgi::Geometry::Line]
        def line = @line ||= Geometry::Line[d, 90.0]

        # Returns a vertical line translated to an x coordinate.
        # @param x [Numeric] x coordinate
        # @return [Sevgi::Geometry::Line]
        def line_at(x) = line.at([x, 0.0])
      end

      private

      def validate_axes(x, y)
        ArgumentError.("Arguments must be Ruler objects") unless [x, y].all?(Ruler)
        ArgumentError.("Grid rulers must fit at least one interval") unless x.n.positive? && y.n.positive?
      end

      def validate_canvas(canvas, x, y)
        return unless canvas

        ArgumentError.("Grid canvas must match the ruler spans") unless canvas.is_a?(Graphics::Canvas)
        return if canvas.width == x.brut && canvas.height == y.brut

        ArgumentError.("Grid canvas must match the ruler spans")
      end
    end
  end
end
