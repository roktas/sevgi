# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Sundries
    class TileTest < Minitest::Test
      def test_tile_rejects_non_geometry_element
        error = assert_raises(ArgumentError) { Tile.new(Object.new) }

        assert_match(/Must be an Element object/, error.message)
      end

      def test_tile_exposes_rows_cols_cells_and_box
        ti = Tile.new(Geometry::Rect[3, 5], nx: 2, ny: 3, position: Geometry::Point[1, 2])

        [
          Geometry::Point[1, 2],
          ti.position,
          3,
          ti.rows.size,
          2,
          ti.cols.size,
          Geometry::Rect[3, 5, position: [1, 2]],
          ti.cell,
          Geometry::Rect[3, 5, position: [4, 7]],
          ti[1][1],
          [
            [Geometry::Rect[3, 5, position: [1, 2]], Geometry::Rect[3, 5, position: [4, 2]]],
            [Geometry::Rect[3, 5, position: [1, 7]], Geometry::Rect[3, 5, position: [4, 7]]],
            [Geometry::Rect[3, 5, position: [1, 12]], Geometry::Rect[3, 5, position: [4, 12]]]
          ],
          ti.rows,
          [
            [
              Geometry::Rect[3, 5, position: [1, 2]],
              Geometry::Rect[3, 5, position: [1, 7]],
              Geometry::Rect[3, 5, position: [1, 12]]
            ],
            [
              Geometry::Rect[3, 5, position: [4, 2]],
              Geometry::Rect[3, 5, position: [4, 7]],
              Geometry::Rect[3, 5, position: [4, 12]]
            ]
          ],
          ti.cols,
          [
            Geometry::Rect[3, 5, position: [1, 2]],
            Geometry::Rect[3, 5, position: [4, 2]]
          ],
          ti.row,
          6.0,
          F.approx(ti.box.width),
          15.0,
          F.approx(ti.box.height)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_tile_each_enumerates_rows
        ti = Tile.new(Geometry::Rect[3, 5], nx: 2, ny: 3, position: Geometry::Point[1, 2])

        expected = [
          [Geometry::Rect[3, 5, position: [1, 2]], Geometry::Rect[3, 5, position: [4, 2]]],
          [Geometry::Rect[3, 5, position: [1, 7]], Geometry::Rect[3, 5, position: [4, 7]]],
          [Geometry::Rect[3, 5, position: [1, 12]], Geometry::Rect[3, 5, position: [4, 12]]]
        ]

        assert_equal(expected, ti.each.to_a)
        assert_equal(expected, ti.each_row.to_a)
        ti.each_with_index { |row, i| assert_equal(expected[i], row) }
      end

      def test_tile_each_col_enumerates_columns
        ti = Tile.new(Geometry::Rect[3, 5], nx: 2, ny: 3, position: Geometry::Point[1, 2])

        expected = [
          [
            Geometry::Rect[3, 5, position: [1, 2]],
            Geometry::Rect[3, 5, position: [1, 7]],
            Geometry::Rect[3, 5, position: [1, 12]]
          ],
          [
            Geometry::Rect[3, 5, position: [4, 2]],
            Geometry::Rect[3, 5, position: [4, 7]],
            Geometry::Rect[3, 5, position: [4, 12]]
          ]
        ]

        assert_equal(expected, ti.each_col.to_a)
        ti.cols.each_with_index { |col, i| assert_equal(expected[i], col) }
      end

      def test_tile_memoizes_rows_cols_and_box
        ti = Tile.new(Geometry::Rect[3, 5], nx: 2, ny: 3, position: Geometry::Point[1, 2])

        [
          ti.rows,
          ti.rows,
          ti.cols,
          ti.cols,
          ti.box,
          ti.box
        ].each_slice(2) { |expected, actual| assert_same(expected, actual) }
      end

      def test_tile_returns_indexed_boxes
        ti = Tile.new(Geometry::Rect[3, 5], nx: 2, ny: 3, position: Geometry::Point[1, 2])

        [
          Geometry::Rect[6, 5, position: [1, 7]],
          ti.rowbox(1),
          Geometry::Rect[6, 5, position: [1, 2]],
          ti.rowbox,
          Geometry::Rect[3, 15, position: [4, 2]],
          ti.colbox(1),
          Geometry::Rect[3, 15, position: [1, 2]],
          ti.colbox
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
