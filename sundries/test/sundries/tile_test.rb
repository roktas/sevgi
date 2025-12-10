# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Sundries
    class TileTest < Minitest::Test
      def test_tile_construction
        ti = Tile.new(Geometry::Rect[3, 5], nx: 2, ny: 3, position: Geometry::Point[1, 2])

        [
          Geometry::Point[1, 2],                    ti.position,
          3,                              ti.rows.size,
          2,                              ti.cols.size,
          Geometry::Rect[3, 5, position: [ 1, 2 ]], ti.cell,
          Geometry::Rect[3, 5, position: [ 4, 7 ]], ti[1][1],
          [
            [ Geometry::Rect[3, 5, position: [ 1,  2 ]], Geometry::Rect[3, 5, position: [ 4,  2 ]] ],
            [ Geometry::Rect[3, 5, position: [ 1,  7 ]], Geometry::Rect[3, 5, position: [ 4,  7 ]] ],
            [ Geometry::Rect[3, 5, position: [ 1, 12 ]], Geometry::Rect[3, 5, position: [ 4, 12 ]] ],
          ],                              ti.rows,
          [
            [ Geometry::Rect[3, 5, position: [ 1, 2 ]], Geometry::Rect[3, 5, position: [ 1, 7 ]], Geometry::Rect[3, 5, position: [ 1, 12 ]] ],
            [ Geometry::Rect[3, 5, position: [ 4, 2 ]], Geometry::Rect[3, 5, position: [ 4, 7 ]], Geometry::Rect[3, 5, position: [ 4, 12 ]] ],
          ],                              ti.cols,
          [
            Geometry::Rect[3, 5, position: [ 1, 2 ]], Geometry::Rect[3, 5, position: [ 4, 2 ]]
          ],                              ti.row,
          6.0,                            F.approx(ti.box.width),
          15.0,                           F.approx(ti.box.height),
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_tile_enumerable_rows
        ti = Tile.new(Geometry::Rect[3, 5], nx: 2, ny: 3, position: Geometry::Point[1, 2])

        expected = [
          [ Geometry::Rect[3, 5, position: [ 1,  2 ]], Geometry::Rect[3, 5, position: [ 4,  2 ]] ],
          [ Geometry::Rect[3, 5, position: [ 1,  7 ]], Geometry::Rect[3, 5, position: [ 4,  7 ]] ],
          [ Geometry::Rect[3, 5, position: [ 1, 12 ]], Geometry::Rect[3, 5, position: [ 4, 12 ]] ],
        ]

        assert_equal(expected, ti.each.to_a)
        assert_equal(expected, ti.each_row.to_a)
        ti.each_with_index { |row, i| assert_equal(expected[i], row) }
      end

      def test_tile_enumerable_cols
        ti = Tile.new(Geometry::Rect[3, 5], nx: 2, ny: 3, position: Geometry::Point[1, 2])

        expected = [
          [ Geometry::Rect[3, 5, position: [ 1, 2 ]],  Geometry::Rect[3, 5, position: [ 1, 7 ]], Geometry::Rect[3, 5, position: [ 1, 12 ]] ],
          [ Geometry::Rect[3, 5, position: [ 4, 2 ]], Geometry::Rect[3, 5,  position: [ 4, 7 ]], Geometry::Rect[3, 5, position: [ 4, 12 ]] ],
        ]

        assert_equal(expected, ti.each_col.to_a)
        ti.cols.each_with_index { |col, i| assert_equal(expected[i], col) }
      end
    end
  end
end
