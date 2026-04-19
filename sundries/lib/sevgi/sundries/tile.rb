# frozen_string_literal: true

module Sevgi
  module Sundries
    class Tile
      include Enumerable

      attr_reader :element, :position, :nx, :ny

      def initialize(element, position: Geometry::Origin, nx: 1, ny: 1)
        raise(ArgumentError, "Must be an Element object: #{element}") unless element.is_a?(Geometry::Element)

        @element  = element
        @position = position

        @nx       = nx
        @ny       = ny
      end

      def [](i)         = rows[i]

      def box           = @box ||= Geometry::Rect[nx * element.box.width, ny * element.box.height, position:]

      def cell          = row.first

      def colbox(i = 0) = Geometry::Rect[element.box.width, box.height, position: coordinate(0, i)]

      def cols          = @cols ||= rows.transpose

      def col(i = 0)    = cols[i]

      def each(...)     = rows.each(...)

      def each_col(...) = cols.each(...)

      def row(i = 0)    = rows[i]

      def rowbox(i = 0) = Geometry::Rect[box.width, element.box.height, position: coordinate(i)]

      def rows          = @rows ||= (0...ny).map { |i| (0...nx).map { |j| element.at(coordinate(i, j)) } }

      alias_method :each_row, :each

      private

        def coordinate(i, j = 0) = position.translate(j * element.box.width, i * element.box.height)
    end
  end
end
