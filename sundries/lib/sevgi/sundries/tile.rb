# frozen_string_literal: true

module Sevgi
  module Sundries
    # Repeats a geometry element over a rectangular row and column layout.
    #
    # The source element's bounding-box width and height become the cell pitch.
    # Indexing is row-first: `tile[row][column]`. Generated cells and collection
    # snapshots are immutable geometry values; no SVG elements are created.
    # @example Address cells by row and column
    #   cell = Sevgi::Geometry::Rect[8, 4]
    #   tile = Sevgi::Sundries::Tile.new(cell, position: [10, 20], nx: 3, ny: 2)
    #   tile[1][2].position.deconstruct # => [26.0, 24.0]
    # @example Inspect the complete, row, and column bounds
    #   cell = Sevgi::Geometry::Rect[8, 4]
    #   tile = Sevgi::Sundries::Tile.new(cell, position: [10, 20], nx: 3, ny: 2)
    #   [tile.box.approx.width, tile.box.approx.height] # => [24.0, 8.0]
    #   tile.rowbox(1).position.deconstruct # => [10.0, 24.0]
    #   tile.colbox(2).position.deconstruct # => [26.0, 20.0]
    # @example Iterate by rows or columns
    #   tile = Sevgi::Sundries::Tile.new(Sevgi::Geometry::Rect[8, 4], nx: 3, ny: 2)
    #   tile.each_row.map(&:size) # => [3, 3]
    #   tile.each_col.map(&:size) # => [2, 2, 2]
    # @see Sevgi::Graphics::Mixtures::Tile
    class Tile
      include Enumerable

      # Returns the source geometry element.
      # @return [Sevgi::Geometry::Element]
      attr_reader :element

      # Returns the tile origin.
      # @return [Sevgi::Geometry::Point]
      attr_reader :position

      # Returns the number of columns.
      # @return [Integer]
      attr_reader :nx

      # Returns the number of rows.
      # @return [Integer]
      attr_reader :ny

      # Creates a tile from a source geometry element.
      # @param element [Sevgi::Geometry::Element] geometry element to repeat
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] tile origin
      # @param nx [Integer] number of columns
      # @param ny [Integer] number of rows
      # @return [void]
      # @raise [Sevgi::ArgumentError] when element is not a geometry element
      # @raise [Sevgi::ArgumentError] when nx or ny is not a positive integer
      # @raise [Sevgi::ArgumentError] when position is not a point or two-number array
      def initialize(element, position: Geometry::Origin, nx: 1, ny: 1)
        ArgumentError.("Must be an Element object: #{element}") unless element.is_a?(Geometry::Element)
        ArgumentError.("Tile nx must be positive") unless nx.is_a?(::Integer) && nx.positive?
        ArgumentError.("Tile ny must be positive") unless ny.is_a?(::Integer) && ny.positive?

        @element = element
        @position = self.class.send(:position, position)

        @nx = nx
        @ny = ny
      end

      # Returns a row by index.
      # @param i [Integer] row index
      # @return [Array<Sevgi::Geometry::Element>, nil]
      def [](i) = rows[i]

      # Returns the bounding rectangle of the whole tile.
      # @return [Sevgi::Geometry::Rect]
      def box = @box ||= Geometry::Rect[nx * element.box.width, ny * element.box.height, position:]

      # Returns the first cell in the tile.
      # @return [Sevgi::Geometry::Element]
      def cell = row.first

      # Returns the bounding rectangle of a column.
      # @param i [Integer] column index
      # @return [Sevgi::Geometry::Rect]
      def colbox(i = 0) = Geometry::Rect[element.box.width, box.height, position: coordinate(0, i)]

      # Returns cells grouped by column.
      # The outer and nested collections are frozen and must be treated as immutable.
      # @return [Array<Array<Sevgi::Geometry::Element>>] frozen columns
      def cols = @cols ||= rows.transpose.map(&:freeze).freeze

      # Returns a column by index.
      # @param i [Integer] column index
      # @return [Array<Sevgi::Geometry::Element>, nil]
      def col(i = 0) = cols[i]

      # Iterates over rows.
      # @yield [row] each row
      # @yieldparam row [Array<Sevgi::Geometry::Element>] row cells
      # @yieldreturn [void]
      # @return [Enumerator, Array<Array<Sevgi::Geometry::Element>>] enumerator without a block, otherwise rows
      def each(...) = rows.each(...)

      # Iterates over columns.
      # @yield [column] each column
      # @yieldparam column [Array<Sevgi::Geometry::Element>] column cells
      # @yieldreturn [void]
      # @return [Enumerator, Array<Array<Sevgi::Geometry::Element>>] enumerator without a block, otherwise columns
      def each_col(...) = cols.each(...)

      # Returns a row by index.
      # @param i [Integer] row index
      # @return [Array<Sevgi::Geometry::Element>, nil]
      def row(i = 0) = rows[i]

      # Returns the bounding rectangle of a row.
      # @param i [Integer] row index
      # @return [Sevgi::Geometry::Rect]
      def rowbox(i = 0) = Geometry::Rect[box.width, element.box.height, position: coordinate(i)]

      # Returns cells grouped by row.
      # The outer and nested collections are frozen and must be treated as immutable.
      # @return [Array<Array<Sevgi::Geometry::Element>>] frozen rows
      def rows = @rows ||= (0...ny).map { |i| (0...nx).map { |j| element.at(coordinate(i, j)) }.freeze }.freeze

      # Iterates over rows.
      # @return [Enumerator, Array<Array<Sevgi::Geometry::Element>>] enumerator without a block, otherwise rows
      alias each_row each

      private

      # Coerces a public tile position.
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] tile origin
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::ArgumentError] when position is not a point or two-number array
      def self.position(position)
        return position if position.is_a?(Geometry::Point)

        unless position.is_a?(::Array) && position.size == 2 && position.all?(::Numeric)
          ArgumentError.("Tile position must be a Point or two-number Array")
        end

        Geometry::Point[*position]
      end

      private_class_method :position

      def coordinate(i, j = 0) = position.translate(j * element.box.width, i * element.box.height)
    end
  end
end
