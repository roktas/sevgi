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
              rect(id: "rect", width: 5, height: 8)
              Tile(nx: 1, dx: 1, ny: 1, dy: 4)
            end
          end

          assert_match(/\bid\b.*\brequired\b/, error.message)
        end

        def test_tile_zero_nx_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8)
              Tile("rect", nx: 0, dx: 1, ny: 1, dy: 4)
            end
          end

          assert_match(/\bnx\b.*\bpositive/, error.message)
        end

        def test_tile_zero_ny_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8)
              Tile("rect", nx: 1, dx: 1, ny: 0, dy: 4)
            end
          end

          assert_match(/\bny\b.*\bpositive/, error.message)
        end

        def test_tile_single
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1-1" href="#rect" class="tile-row-1 tile-row-first tile-row-last tile-col-1 tile-col-first tile-col-last"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            Tile("rect", nx: 1, dx: 1, ny: 1, dy: 4)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_offset
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1-1" href="#rect" class="tile-row-1 tile-row-first tile-row-last tile-col-1 tile-col-first tile-col-last" x="3" y="5"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            Tile("rect", nx: 1, dx: 1, ox: 3, ny: 1, dy: 4, oy: 5)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_without_block
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1-1" href="#rect" class="tile-row-1 tile-row-first tile-col-1 tile-col-first"/>
              <use id="rect-1-2" href="#rect" class="tile-row-1 tile-row-first tile-col-2 tile-col-last" x="1"/>
              <use id="rect-2-1" href="#rect" class="tile-row-2 tile-col-1 tile-col-first" y="4"/>
              <use id="rect-2-2" href="#rect" class="tile-row-2 tile-col-2 tile-col-last" x="1" y="4"/>
              <use id="rect-3-1" href="#rect" class="tile-row-3 tile-row-last tile-col-1 tile-col-first" y="8"/>
              <use id="rect-3-2" href="#rect" class="tile-row-3 tile-row-last tile-col-2 tile-col-last" x="1" y="8"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            Tile("rect", nx: 2, dx: 1, ny: 3, dy: 4)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_with_block
          expected = <<~SVG.chomp
            <svg>
              <defs>
                <g id="rect">
                  <rect width="5" height="8"/>
                </g>
              </defs>
              <use id="rect-1-1" href="#rect" class="tile-row-1 tile-row-first tile-col-1 tile-col-first"/>
              <use id="rect-1-2" href="#rect" class="tile-row-1 tile-row-first tile-col-2 tile-col-last" x="1"/>
              <use id="rect-2-1" href="#rect" class="tile-row-2 tile-col-1 tile-col-first" y="4"/>
              <use id="rect-2-2" href="#rect" class="tile-row-2 tile-col-2 tile-col-last" x="1" y="4"/>
              <use id="rect-3-1" href="#rect" class="tile-row-3 tile-row-last tile-col-1 tile-col-first" y="8"/>
              <use id="rect-3-2" href="#rect" class="tile-row-3 tile-row-last tile-col-2 tile-col-last" x="1" y="8"/>
            </svg>
          SVG

          actual = SVG DOC do
            Tile("rect", nx: 2, dx: 1, ny: 3, dy: 4) { rect(width: 5, height: 8) }
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_with_proc
          expected = <<~SVG.chomp
            <svg>
              <defs>
                <g id="rect">
                  <rect width="5" height="8"/>
                </g>
              </defs>
              <use id="rect-1-1" href="#rect"/>
              <use id="rect-1-2" href="#rect" x="1"/>
              <use id="rect-2-1" href="#rect" y="4"/>
              <use id="rect-2-2" href="#rect" x="1" y="4"/>
              <use id="rect-3-1" href="#rect" y="8"/>
              <use id="rect-3-2" href="#rect" x="1" y="8"/>
            </svg>
          SVG

          proc = proc do |element, x:, y:, nx:, ny:|
            element.attributes.delete(:class)
          end

          actual = SVG DOC do
            Tile("rect", nx: 2, dx: 1, ny: 3, dy: 4, proc:) { rect(width: 5, height: 8) }
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_bang
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <g id="myrect" class="mytile">
                <use id="myrect-1-1" href="#myrect" class="tile-row-1 tile-row-first tile-col-1 tile-col-first"/>
                <use id="myrect-1-2" href="#myrect" class="tile-row-1 tile-row-first tile-col-2 tile-col-last" x="1"/>
                <use id="myrect-2-1" href="#myrect" class="tile-row-2 tile-col-1 tile-col-first" y="4"/>
                <use id="myrect-2-2" href="#myrect" class="tile-row-2 tile-col-2 tile-col-last" x="1" y="4"/>
                <use id="myrect-3-1" href="#myrect" class="tile-row-3 tile-row-last tile-col-1 tile-col-first" y="8"/>
                <use id="myrect-3-2" href="#myrect" class="tile-row-3 tile-row-last tile-col-2 tile-col-last" x="1" y="8"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            Tile!("myrect", "mytile", nx: 2, dx: 1, ny: 3, dy: 4)
          end.Render

          assert_equal(expected, actual)
        end
      end

      class TileXTest < Minitest::Test
        DOC = :minimal

        def test_tile_x_no_id_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8)
              TileX(n: 1, d: 1)
            end
          end

          assert_match(/\bid\b.*\brequired\b/, error.message)
        end

        def test_tile_x_zero_n_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8)
              TileX("rect", n: 0, d: 1)
            end
          end

          assert_match(/\bn\b.*\bpositive/, error.message)
        end

        def test_tile_x_single
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect" class="tile-col-1 tile-col-first tile-col-last"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            TileX("rect", n: 1, d: 1)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_x_offset
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect" class="tile-col-1 tile-col-first tile-col-last" x="3"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            TileX("rect", n: 1, d: 1, o: 3)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_x_without_block
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect" class="tile-col-1 tile-col-first"/>
              <use id="rect-2" href="#rect" class="tile-col-2 tile-col-last" x="1"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            TileX("rect", n: 2, d: 1)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_x_with_block
          expected = <<~SVG.chomp
            <svg>
              <defs>
                <g id="rect">
                  <rect width="5" height="8"/>
                </g>
              </defs>
              <use id="rect-1" href="#rect" class="tile-col-1 tile-col-first"/>
              <use id="rect-2" href="#rect" class="tile-col-2 tile-col-last" x="1"/>
            </svg>
          SVG

          actual = SVG DOC do
            TileX("rect", n: 2, d: 1) { rect(width: 5, height: 8) }
          end.Render

          assert_equal(expected, actual)
        end
      end

      class TileYTest < Minitest::Test
        DOC = :minimal

        def test_tile_y_no_id_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8)
              TileY(n: 1, d: 1)
            end
          end

          assert_match(/\bid\b.*\brequired\b/, error.message)
        end

        def test_tile_y_zero_n_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(id: "rect", width: 5, height: 8)
              TileY("rect", n: 0, d: 1)
            end
          end

          assert_match(/\bn\b.*\bpositive/, error.message)
        end

        def test_tile_y_single
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect" class="tile-row-1 tile-row-first tile-row-last"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            TileY("rect", n: 1, d: 1)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_y_offset
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect" class="tile-row-1 tile-row-first tile-row-last" y="3"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            TileY("rect", n: 1, d: 1, o: 3)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_y_multiple
          expected = <<~SVG.chomp
            <svg>
              <rect id="rect" width="5" height="8"/>
              <use id="rect-1" href="#rect" class="tile-row-1 tile-row-first"/>
              <use id="rect-2" href="#rect" class="tile-row-2 tile-row-last" y="1"/>
            </svg>
          SVG

          actual = SVG DOC do
            rect(id: "rect", width: 5, height: 8)
            TileY("rect", n: 2, d: 1)
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_y_with_block
          expected = <<~SVG.chomp
            <svg>
              <defs>
                <g id="rect">
                  <rect width="5" height="8"/>
                </g>
              </defs>
              <use id="rect-1" href="#rect" class="tile-row-1 tile-row-first"/>
              <use id="rect-2" href="#rect" class="tile-row-2 tile-row-last" y="1"/>
            </svg>
          SVG

          actual = SVG DOC do
            TileY("rect", n: 2, d: 1) { rect(width: 5, height: 8) }
          end.Render

          assert_equal(expected, actual)
        end
      end
    end
  end
end
