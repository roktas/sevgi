# frozen_string_literal: true

module Sevgi
  module Sundries
    # Repeats a geometry element over a rectangular row and column layout.
    class Tile
      include Enumerable

      # @!attribute [r] element
      #   @return [Sevgi::Geometry::Element] source element repeated by the tile
      # @!attribute [r] position
      #   @return [Sevgi::Geometry::Point] tile origin
      # @!attribute [r] nx
      #   @return [Integer] number of columns
      # @!attribute [r] ny
      #   @return [Integer] number of rows
      attr_reader :element, :position, :nx, :ny

      # Creates a tile from a source geometry element.
      # @param element [Sevgi::Geometry::Element] geometry element to repeat
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] tile origin
      # @param nx [Integer] number of columns
      # @param ny [Integer] number of rows
      # @return [void]
      # @raise [Sevgi::ArgumentError] when element is not a geometry element
      # @raise [Sevgi::ArgumentError] when nx or ny is not a positive integer
      def initialize(element, position: Geometry::Origin, nx: 1, ny: 1)
        ArgumentError.("Must be an Element object: #{element}") unless element.is_a?(Geometry::Element)
        ArgumentError.("Tile nx must be positive") unless nx.is_a?(::Integer) && nx.positive?
        ArgumentError.("Tile ny must be positive") unless ny.is_a?(::Integer) && ny.positive?

        @element = element
        @position = position

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
      # @return [Array<Array<Sevgi::Geometry::Element>>]
      def cols = @cols ||= rows.transpose

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
      # @return [Array<Array<Sevgi::Geometry::Element>>]
      def rows = @rows ||= (0...ny).map { |i| (0...nx).map { |j| element.at(coordinate(i, j)) } }

      # Iterates over rows.
      # @return [Enumerator, Array<Array<Sevgi::Geometry::Element>>] enumerator without a block, otherwise rows
      alias each_row each

      private

      def coordinate(i, j = 0) = position.translate(j * element.box.width, i * element.box.height)
    end
  end
end
