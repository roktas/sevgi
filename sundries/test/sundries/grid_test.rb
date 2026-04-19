# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Sundries
    class GridTest < Minitest::Test
      def test_grid_construction
        [
          # Ordinary construction
          Grid.new(
            x: rx = Ruler.new(unit: 6, multiple: 5, brut: 210, margin: 15),
            y: ry = Ruler.new(unit: 6, multiple: 5, brut: 297, margin: 15),
          ),
          # Alternative construction
          Grid[rx, ry]
        ].each do |grid|
          [
            180.0,       grid.x.d,
            30.0,        grid.x.u,
            6.0,         grid.x.su,
            6.0,         grid.y.su,
            30.0,        grid.y.u,
            240.0,       grid.y.d,
            6,           grid.x.n,
            7,           grid.x.ds.size,
            8,           grid.y.n,
            9,           grid.y.ds.size,
            grid.height, grid.y.d,
            grid.width,  grid.x.d,
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end
      end

      def test_grid_x_major
        grid = Grid.new(
          x: Ruler.new(unit: 6, multiple: 5, brut: 210, margin: 15),
          y: Ruler.new(unit: 6, multiple: 5, brut: 297, margin: 15),
        )

        grid.x.major.lines.each { assert(it.is_a?(Geometry::Line)) }

        [
          [
            [ [ 0.0,   0.0 ], [ 180.0,   0.0 ] ],
            [ [ 0.0,  30.0 ], [ 180.0,  30.0 ] ],
            [ [ 0.0,  60.0 ], [ 180.0,  60.0 ] ],
            [ [ 0.0,  90.0 ], [ 180.0,  90.0 ] ],
            [ [ 0.0, 120.0 ], [ 180.0, 120.0 ] ],
            [ [ 0.0, 150.0 ], [ 180.0, 150.0 ] ],
            [ [ 0.0, 180.0 ], [ 180.0, 180.0 ] ],
            [ [ 0.0, 210.0 ], [ 180.0, 210.0 ] ],
            [ [ 0.0, 240.0 ], [ 180.0, 240.0 ] ],
          ],             grid.x.major.xys,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_grid_x_halve
        grid = Grid.new(
          x: Ruler.new(unit: 6, multiple: 5, brut: 210, margin: 15),
          y: Ruler.new(unit: 6, multiple: 5, brut: 297, margin: 15),
        )

        grid.x.halve.lines.each { assert(it.is_a?(Geometry::Line)) }

        [
          [
            [ [ 0.0,  15.0 ], [ 180.0,  15.0 ] ],
            [ [ 0.0,  45.0 ], [ 180.0,  45.0 ] ],
            [ [ 0.0,  75.0 ], [ 180.0,  75.0 ] ],
            [ [ 0.0, 105.0 ], [ 180.0, 105.0 ] ],
            [ [ 0.0, 135.0 ], [ 180.0, 135.0 ] ],
            [ [ 0.0, 165.0 ], [ 180.0, 165.0 ] ],
            [ [ 0.0, 195.0 ], [ 180.0, 195.0 ] ],
            [ [ 0.0, 225.0 ], [ 180.0, 225.0 ] ],
          ],             grid.x.halve.xys,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_grid_x_minor
        grid = Grid.new(
          x: Ruler.new(unit: 6, multiple: 5, brut: 210, margin: 15),
          y: Ruler.new(unit: 6, multiple: 5, brut: 297, margin: 15),
        )

        grid.x.minor.lines.each { assert(it.is_a?(Geometry::Line)) }

        [
          [
            [ [ 0.0,   0.0 ], [ 180.0,   0.0 ] ],
            [ [ 0.0,   6.0 ], [ 180.0,   6.0 ] ],
            [ [ 0.0,  12.0 ], [ 180.0,  12.0 ] ],
            [ [ 0.0,  18.0 ], [ 180.0,  18.0 ] ],
            [ [ 0.0,  24.0 ], [ 180.0,  24.0 ] ],
            [ [ 0.0,  30.0 ], [ 180.0,  30.0 ] ],
            [ [ 0.0,  36.0 ], [ 180.0,  36.0 ] ],
            [ [ 0.0,  42.0 ], [ 180.0,  42.0 ] ],
            [ [ 0.0,  48.0 ], [ 180.0,  48.0 ] ],
            [ [ 0.0,  54.0 ], [ 180.0,  54.0 ] ],
            [ [ 0.0,  60.0 ], [ 180.0,  60.0 ] ],
            [ [ 0.0,  66.0 ], [ 180.0,  66.0 ] ],
            [ [ 0.0,  72.0 ], [ 180.0,  72.0 ] ],
            [ [ 0.0,  78.0 ], [ 180.0,  78.0 ] ],
            [ [ 0.0,  84.0 ], [ 180.0,  84.0 ] ],
            [ [ 0.0,  90.0 ], [ 180.0,  90.0 ] ],
            [ [ 0.0,  96.0 ], [ 180.0,  96.0 ] ],
            [ [ 0.0, 102.0 ], [ 180.0, 102.0 ] ],
            [ [ 0.0, 108.0 ], [ 180.0, 108.0 ] ],
            [ [ 0.0, 114.0 ], [ 180.0, 114.0 ] ],
            [ [ 0.0, 120.0 ], [ 180.0, 120.0 ] ],
            [ [ 0.0, 126.0 ], [ 180.0, 126.0 ] ],
            [ [ 0.0, 132.0 ], [ 180.0, 132.0 ] ],
            [ [ 0.0, 138.0 ], [ 180.0, 138.0 ] ],
            [ [ 0.0, 144.0 ], [ 180.0, 144.0 ] ],
            [ [ 0.0, 150.0 ], [ 180.0, 150.0 ] ],
            [ [ 0.0, 156.0 ], [ 180.0, 156.0 ] ],
            [ [ 0.0, 162.0 ], [ 180.0, 162.0 ] ],
            [ [ 0.0, 168.0 ], [ 180.0, 168.0 ] ],
            [ [ 0.0, 174.0 ], [ 180.0, 174.0 ] ],
            [ [ 0.0, 180.0 ], [ 180.0, 180.0 ] ],
            [ [ 0.0, 186.0 ], [ 180.0, 186.0 ] ],
            [ [ 0.0, 192.0 ], [ 180.0, 192.0 ] ],
            [ [ 0.0, 198.0 ], [ 180.0, 198.0 ] ],
            [ [ 0.0, 204.0 ], [ 180.0, 204.0 ] ],
            [ [ 0.0, 210.0 ], [ 180.0, 210.0 ] ],
            [ [ 0.0, 216.0 ], [ 180.0, 216.0 ] ],
            [ [ 0.0, 222.0 ], [ 180.0, 222.0 ] ],
            [ [ 0.0, 228.0 ], [ 180.0, 228.0 ] ],
            [ [ 0.0, 234.0 ], [ 180.0, 234.0 ] ],
            [ [ 0.0, 240.0 ], [ 180.0, 240.0 ] ],
          ],             grid.x.minor.xys,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_grid_y_major
        grid = Grid.new(
          x: Ruler.new(unit: 6, multiple: 5, brut: 210, margin: 15),
          y: Ruler.new(unit: 6, multiple: 5, brut: 297, margin: 15),
        )

        grid.y.major.lines.each { assert(it.is_a?(Geometry::Line)) }

        [
          [
            [ [   0.0, 0.0 ], [   0.0, 240.0 ] ],
            [ [  30.0, 0.0 ], [  30.0, 240.0 ] ],
            [ [  60.0, 0.0 ], [  60.0, 240.0 ] ],
            [ [  90.0, 0.0 ], [  90.0, 240.0 ] ],
            [ [ 120.0, 0.0 ], [ 120.0, 240.0 ] ],
            [ [ 150.0, 0.0 ], [ 150.0, 240.0 ] ],
            [ [ 180.0, 0.0 ], [ 180.0, 240.0 ] ],
          ],             grid.y.major.xys,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_grid_y_halve
        grid = Grid.new(
          x: Ruler.new(unit: 6, multiple: 5, brut: 210, margin: 15),
          y: Ruler.new(unit: 6, multiple: 5, brut: 297, margin: 15),
        )

        grid.y.halve.lines.each { assert(it.is_a?(Geometry::Line)) }

        [
          [
            [ [  15.0, 0.0 ], [  15.0, 240.0 ] ],
            [ [  45.0, 0.0 ], [  45.0, 240.0 ] ],
            [ [  75.0, 0.0 ], [  75.0, 240.0 ] ],
            [ [ 105.0, 0.0 ], [ 105.0, 240.0 ] ],
            [ [ 135.0, 0.0 ], [ 135.0, 240.0 ] ],
            [ [ 165.0, 0.0 ], [ 165.0, 240.0 ] ],
          ],             grid.y.halve.xys,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_grid_y_minor
        grid = Grid.new(
          x: Ruler.new(unit: 6, multiple: 5, brut: 210, margin: 15),
          y: Ruler.new(unit: 6, multiple: 5, brut: 297, margin: 15),
        )

        grid.y.minor.lines.each { assert(it.is_a?(Geometry::Line)) }

        [
          [
            [ [   0.0, 0.0 ], [   0.0, 240.0 ] ],
            [ [   6.0, 0.0 ], [   6.0, 240.0 ] ],
            [ [  12.0, 0.0 ], [  12.0, 240.0 ] ],
            [ [  18.0, 0.0 ], [  18.0, 240.0 ] ],
            [ [  24.0, 0.0 ], [  24.0, 240.0 ] ],
            [ [  30.0, 0.0 ], [  30.0, 240.0 ] ],
            [ [  36.0, 0.0 ], [  36.0, 240.0 ] ],
            [ [  42.0, 0.0 ], [  42.0, 240.0 ] ],
            [ [  48.0, 0.0 ], [  48.0, 240.0 ] ],
            [ [  54.0, 0.0 ], [  54.0, 240.0 ] ],
            [ [  60.0, 0.0 ], [  60.0, 240.0 ] ],
            [ [  66.0, 0.0 ], [  66.0, 240.0 ] ],
            [ [  72.0, 0.0 ], [  72.0, 240.0 ] ],
            [ [  78.0, 0.0 ], [  78.0, 240.0 ] ],
            [ [  84.0, 0.0 ], [  84.0, 240.0 ] ],
            [ [  90.0, 0.0 ], [  90.0, 240.0 ] ],
            [ [  96.0, 0.0 ], [  96.0, 240.0 ] ],
            [ [ 102.0, 0.0 ], [ 102.0, 240.0 ] ],
            [ [ 108.0, 0.0 ], [ 108.0, 240.0 ] ],
            [ [ 114.0, 0.0 ], [ 114.0, 240.0 ] ],
            [ [ 120.0, 0.0 ], [ 120.0, 240.0 ] ],
            [ [ 126.0, 0.0 ], [ 126.0, 240.0 ] ],
            [ [ 132.0, 0.0 ], [ 132.0, 240.0 ] ],
            [ [ 138.0, 0.0 ], [ 138.0, 240.0 ] ],
            [ [ 144.0, 0.0 ], [ 144.0, 240.0 ] ],
            [ [ 150.0, 0.0 ], [ 150.0, 240.0 ] ],
            [ [ 156.0, 0.0 ], [ 156.0, 240.0 ] ],
            [ [ 162.0, 0.0 ], [ 162.0, 240.0 ] ],
            [ [ 168.0, 0.0 ], [ 168.0, 240.0 ] ],
            [ [ 174.0, 0.0 ], [ 174.0, 240.0 ] ],
            [ [ 180.0, 0.0 ], [ 180.0, 240.0 ] ],
          ],             grid.y.minor.xys,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_grid_tiled
        gr = Grid.new(
            x: Ruler.new(unit: 2, multiple: 2, brut: 8),
            y: Ruler.new(unit: 1, multiple: 2, brut: 6),
        )

        [
          Geometry::Origin,                         gr.position,
          3,                                        gr.rows.size,
          2,                                        gr.cols.size,
          8.0,                                      F.approx(gr.box.width),
          6.0,                                      F.approx(gr.box.height),
          Geometry::Rect[4, 2],                     gr.cell,
          Geometry::Rect[4, 2, position: [ 4, 2 ]], gr[1][1],
          [
            [ Geometry::Rect[4, 2, position:   Geometry::Origin], Geometry::Rect[4, 2, position: [ 4, 0 ]] ],
            [ Geometry::Rect[4, 2, position: [ 0, 2 ]], Geometry::Rect[4, 2, position: [ 4, 2 ]] ],
            [ Geometry::Rect[4, 2, position: [ 0, 4 ]], Geometry::Rect[4, 2, position: [ 4, 4 ]] ],
          ],                                        gr.rows,
          [
            [ Geometry::Rect[4, 2, position: Geometry::Origin], Geometry::Rect[4, 2, position: [ 0, 2 ]], Geometry::Rect[4, 2, position: [ 0, 4 ]] ],
            [ Geometry::Rect[4, 2, position: [ 4, 0 ]], Geometry::Rect[4, 2, position: [ 4, 2 ]], Geometry::Rect[4, 2, position: [ 4, 4 ]] ],
          ],                                        gr.cols,
          [
            Geometry::Rect[4, 2, position:     Geometry::Origin], Geometry::Rect[4, 2, position: [ 4, 0 ]]
          ],                                        gr.row,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_grid_boxes
        gr = Grid.new(
            x: Ruler.new(unit: 2, multiple: 2, brut: 8),
            y: Ruler.new(unit: 1, multiple: 2, brut: 6),
        )

        [
          Geometry::Rect[4, 6, position: [ 4, 0 ]],         gr.colbox(1),
          Geometry::Rect[4, 6, position: Geometry::Origin], gr.colbox,
          Geometry::Rect[8, 2, position: [ 0, 2 ]],         gr.rowbox(1),
          Geometry::Rect[8, 2, position: Geometry::Origin], gr.rowbox,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
