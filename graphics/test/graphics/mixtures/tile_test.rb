# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class TileTest < Minitest::Test
        DOC = :minimal

        def test_tile_no_id_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).Tile(nx: 1, dx: 1, ny: 1, dy: 4)
            end
          end

          assert_match(/\bmust\b.*\bid\b/, error.message)
        end

        def test_tile_zero_nx_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8).Tile(nx: 0, dx: 1, ny: 1, dy: 4)
            end
          end

          assert_match(/\bnx\b.*\bpositive/, error.message)
        end

        def test_tile_zero_ny_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8).Tile(nx: 1, dx: 1, ny: 0, dy: 4)
            end
          end

          assert_match(/\bny\b.*\bpositive/, error.message)
        end

        def test_tile_single
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1-1" href="#rect"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).Tile(nx: 1, dx: 1, ny: 1, dy: 4)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_offset
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1-1" href="#rect" x="3" y="5"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).Tile(nx: 1, dx: 1, ox: 3, ny: 1, dy: 4, oy: 5)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_multiple
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1-1" href="#rect"/>
              <use id="rect-1-2" href="#rect" x="1"/>
              <use id="rect-2-1" href="#rect" y="4"/>
              <use id="rect-2-2" href="#rect" x="1" y="4"/>
              <use id="rect-3-1" href="#rect" y="8"/>
              <use id="rect-3-2" href="#rect" x="1" y="8"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).Tile(nx: 2, dx: 1, ny: 3, dy: 4)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_by_id
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <g>
                <use id="rect-1-1" href="#rect"/>
                <use id="rect-1-2" href="#rect" x="1"/>
                <use id="rect-2-1" href="#rect" y="4"/>
                <use id="rect-2-2" href="#rect" x="1" y="4"/>
                <use id="rect-3-1" href="#rect" y="8"/>
                <use id="rect-3-2" href="#rect" x="1" y="8"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            g do
              Tile("rect", nx: 2, dx: 1, ny: 3, dy: 4)
            end
          end.Render

          assert_equal(expected, actual)
        end
      end

      class TileXTest < Minitest::Test
        DOC = :minimal

        def test_tile_x_no_id_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).TileX(n: 1, d: 1)
            end
          end

          assert_match(/\bmust\b.*\bid\b/, error.message)
        end

        def test_tile_x_zero_n_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8).TileX(n: 0, d: 1)
            end
          end

          assert_match(/\bn\b.*\bpositive/, error.message)
        end

        def test_tile_x_single
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).TileX(n: 1, d: 1)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_x_offset
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect" x="3"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).TileX(n: 1, d: 1, o: 3)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_x_multiple
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect"/>
              <use id="rect-2" href="#rect" x="1"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).TileX(n: 2, d: 1)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_x_by_id
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <g>
                <use id="rect-1" href="#rect"/>
                <use id="rect-2" href="#rect" x="1"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            g { TileX("rect", n: 2, d: 1) }
          end.Render

          assert_equal(expected, actual)
        end
      end

      class TileYTest < Minitest::Test
        DOC = :minimal

        def test_tile_y_no_id_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).TileY(n: 1, d: 1)
            end
          end

          assert_match(/\bmust\b.*\bid\b/, error.message)
        end

        def test_tile_y_zero_n_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8).TileY(n: 0, d: 1)
            end
          end

          assert_match(/\bn\b.*\bpositive/, error.message)
        end

        def test_tile_y_single
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).TileY(n: 1, d: 1)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_y_offset
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect" y="3"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).TileY(n: 1, d: 1, o: 3)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_y_multiple
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect"/>
              <use id="rect-2" href="#rect" y="1"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8).TileY(n: 2, d: 1)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_y_by_id
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <g>
                <use id="rect-1" href="#rect"/>
                <use id="rect-2" href="#rect" y="1"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            g { TileY("rect", n: 2, d: 1) }
          end.Render

          assert_equal(expected, actual)
        end
      end
    end
  end
end