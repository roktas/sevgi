# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class TileTest < Minitest::Test
      def test_tile_construction
        ti = Tile.new(Rect[3, 5], nx: 2, ny: 3, position: Point[1, 2])

        [
          Point[1, 2],                    ti.position,
          3,                              ti.rows.size,
          2,                              ti.cols.size,
          Rect[3, 5, position: [ 1, 2 ]], ti.cell,
          Rect[3, 5, position: [ 4, 7 ]], ti[1][1],
          [
            [ Rect[3, 5, position: [ 1,  2 ]], Rect[3, 5, position: [ 4,  2 ]] ],
            [ Rect[3, 5, position: [ 1,  7 ]], Rect[3, 5, position: [ 4,  7 ]] ],
            [ Rect[3, 5, position: [ 1, 12 ]], Rect[3, 5, position: [ 4, 12 ]] ],
          ],                              ti.rows,
          [
            [ Rect[3, 5, position: [ 1, 2 ]], Rect[3, 5, position: [ 1, 7 ]], Rect[3, 5, position: [ 1, 12 ]] ],
            [ Rect[3, 5, position: [ 4, 2 ]], Rect[3, 5, position: [ 4, 7 ]], Rect[3, 5, position: [ 4, 12 ]] ],
          ],                              ti.cols,
          [
            Rect[3, 5, position: [ 1, 2 ]], Rect[3, 5, position: [ 4, 2 ]]
          ],                              ti.row,
          6.0,                            F.approx(ti.box.width),
          15.0,                           F.approx(ti.box.height),
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_tile_enumerable_rows
        ti = Tile.new(Rect[3, 5], nx: 2, ny: 3, position: Point[1, 2])

        expected = [
          [ Rect[3, 5, position: [ 1,  2 ]], Rect[3, 5, position: [ 4,  2 ]] ],
          [ Rect[3, 5, position: [ 1,  7 ]], Rect[3, 5, position: [ 4,  7 ]] ],
          [ Rect[3, 5, position: [ 1, 12 ]], Rect[3, 5, position: [ 4, 12 ]] ],
        ]

        assert_equal(expected, ti.each.to_a)
        assert_equal(expected, ti.each_row.to_a)
        ti.each_with_index { |row, i| assert_equal(expected[i], row) }
      end

      def test_tile_enumerable_cols
        ti = Tile.new(Rect[3, 5], nx: 2, ny: 3, position: Point[1, 2])

        expected = [
          [ Rect[3, 5, position: [ 1, 2 ]],  Rect[3, 5, position: [ 1, 7 ]], Rect[3, 5, position: [ 1, 12 ]] ],
          [ Rect[3, 5, position: [ 4, 2 ]], Rect[3, 5,  position: [ 4, 7 ]], Rect[3, 5, position: [ 4, 12 ]] ],
        ]

        assert_equal(expected, ti.each_col.to_a)
        ti.cols.each_with_index { |col, i| assert_equal(expected[i], col) }
      end
    end
  end
end
