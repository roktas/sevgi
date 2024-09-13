# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class ReplicateTest < Minitest::Test
        DOC = :minimal

        def test_replicate_zero_nx_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).Replicate(nx: 0, dx: 1, ny: 1, dy: 4, ix: "ix", iy: "iy", id: "ia")
            end
          end

          assert_match(/\bnx\b.*\bpositive/, error.message)
        end

        def test_replicate_zero_ny_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).Replicate(nx: 1, dx: 1, ny: 0, dy: 4, ix: "ix", iy: "iy", id: "ia")
            end
          end

          assert_match(/\bny\b.*\bpositive/, error.message)
        end

        def test_replicate_with_block_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).Replicate(nx: 1, dx: 1, ny: 1, dy: 4, ix: "ix", iy: "iy", id: "ia") do
              end
            end
          end

          assert_match(/\b[Bb]lock\b.*\bnot allow/, error.message)
        end

        def test_replicate_single
          expected = <<~SVG.chomp
            <svg>
              <g id="ia">
                <g id="iy-1">
                  <rect id="ix-1-1" width="5" height="8"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).Replicate(nx: 1, dx: 1, ny: 1, dy: 4, ix: "ix", iy: "iy", id: "ia")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_multiple_with_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <g id="ia">
                <g id="iy-1">
                  <rect id="ix-1-1" width="5" height="8"/>
                  <rect id="ix-1-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
                <g id="iy-2" transform="translate(0 4)">
                  <rect id="ix-2-1" width="5" height="8"/>
                  <rect id="ix-2-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
                <g id="iy-3" transform="translate(0 8)">
                  <rect id="ix-3-1" width="5" height="8"/>
                  <rect id="ix-3-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).Replicate(nx: 2, dx: 1, ny: 3, dy: 4, ix: "ix", iy: "iy", id: "ia")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_multiple_without_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <g>
                <g id="iy-1">
                  <rect id="ix-1-1" width="5" height="8"/>
                  <rect id="ix-1-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
                <g id="iy-2" transform="translate(0 4)">
                  <rect id="ix-2-1" width="5" height="8"/>
                  <rect id="ix-2-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
                <g id="iy-3" transform="translate(0 8)">
                  <rect id="ix-3-1" width="5" height="8"/>
                  <rect id="ix-3-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).Replicate(nx: 2, dx: 1, ny: 3, dy: 4, ix: "ix", iy: "iy")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_multiple_with_column_ids
          expected = <<~SVG.chomp
            <svg>
              <g>
                <g>
                  <rect id="ix-1-1" width="5" height="8"/>
                  <rect id="ix-1-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
                <g transform="translate(0 4)">
                  <rect id="ix-2-1" width="5" height="8"/>
                  <rect id="ix-2-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
                <g transform="translate(0 8)">
                  <rect id="ix-3-1" width="5" height="8"/>
                  <rect id="ix-3-2" width="5" height="8" transform="translate(1 0)"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).Replicate(nx: 2, dx: 1, ny: 3, dy: 4, ix: "ix")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_multiple_without_any_id
          expected = <<~SVG.chomp
            <svg>
              <g>
                <g>
                  <rect width="5" height="8"/>
                  <rect width="5" height="8" transform="translate(1 0)"/>
                </g>
                <g transform="translate(0 4)">
                  <rect width="5" height="8"/>
                  <rect width="5" height="8" transform="translate(1 0)"/>
                </g>
                <g transform="translate(0 8)">
                  <rect width="5" height="8"/>
                  <rect width="5" height="8" transform="translate(1 0)"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).Replicate(nx: 2, dx: 1, ny: 3, dy: 4)
          end.Render

          assert_equal(expected, actual)
        end
      end

      class ReplicateHTest < Minitest::Test
        DOC = :minimal

        def test_replicate_h_zero_n_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).ReplicateH(n: 0, d: 1, i: "iy", id: "ia")
            end
          end

          assert_match(/\bn\b.*\bpositive/, error.message)
        end

        def test_replicate_h_with_block_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).ReplicateH(n: 1, d: 1, i: "iy", id: "ia") do
              end
            end
          end

          assert_match(/\b[Bb]lock\b.*\bnot allow/, error.message)
        end

        def test_replicate_h_single
          expected = <<~SVG.chomp
            <svg>
              <g id="ia">
                <rect id="iy-1" width="5" height="8"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).ReplicateH(n: 1, d: 1, i: "iy", id: "ia")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_h_multiple_with_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <g id="ia">
                <rect id="iy-1" width="5" height="8"/>
                <rect id="iy-2" width="5" height="8" transform="translate(1 0)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).ReplicateH(n: 2, d: 1, i: "iy", id: "ia")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_h_multiple_without_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <g>
                <rect id="iy-1" width="5" height="8"/>
                <rect id="iy-2" width="5" height="8" transform="translate(1 0)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).ReplicateH(n: 2, d: 1, i: "iy")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_h_multiple_without_any_id
          expected = <<~SVG.chomp
            <svg>
              <g>
                <rect width="5" height="8"/>
                <rect width="5" height="8" transform="translate(1 0)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).ReplicateH(n: 2, d: 1)
          end.Render

          assert_equal(expected, actual)
        end
      end

      class ReplicateVTest < Minitest::Test
        DOC = :minimal

        def test_replicate_v_zero_n_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).ReplicateV(n: 0, d: 1, i: "ix", id: "ia")
            end
          end

          assert_match(/\bn\b.*\bpositive/, error.message)
        end

        def test_replicate_v_zero_with_block_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              rect(width: 5, height: 8).ReplicateV(n: 1, d: 1, i: "ix", id: "ia") do
              end
            end
          end

          assert_match(/\b[Bb]lock\b.*\bnot allow/, error.message)
        end

        def test_replicate_v_single
          expected = <<~SVG.chomp
            <svg>
              <g id="ia">
                <rect id="ix-1" width="5" height="8"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).ReplicateV(n: 1, d: 1, i: "ix", id: "ia")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_v_multiple_with_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <g id="ia">
                <rect id="ix-1" width="5" height="8"/>
                <rect id="ix-2" width="5" height="8" transform="translate(0 1)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).ReplicateV(n: 2, d: 1, i: "ix", id: "ia")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_v_multiple_without_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <g>
                <rect id="ix-1" width="5" height="8"/>
                <rect id="ix-2" width="5" height="8" transform="translate(0 1)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).ReplicateV(n: 2, d: 1, i: "ix")
          end.Render

          assert_equal(expected, actual)
        end

        def test_replicate_v_multiple_without_any_id
          expected = <<~SVG.chomp
            <svg>
              <g>
                <rect width="5" height="8"/>
                <rect width="5" height="8" transform="translate(0 1)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            rect(width: 5, height: 8).ReplicateV(n: 2, d: 1)
          end.Render

          assert_equal(expected, actual)
        end
      end

      class TileTest < Minitest::Test
        DOC = :minimal

        def test_tile_zero_nx_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              Tile("rectangular", nx: 0, dx: 1, ny: 1, dy: 4, ix: "ix", iy: "iy", id: "ia") do
                rect(width: 5, height: 8)
              end
            end
          end

          assert_match(/\bnx\b.*\bpositive/, error.message)
        end

        def test_tile_zero_ny_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              Tile("rectangular", nx: 1, dx: 1, ny: 0, dy: 4, ix: "ix", iy: "iy", id: "ia") do
                rect(width: 5, height: 8)
              end
            end
          end

          assert_match(/\bny\b.*\bpositive/, error.message)
        end

        def test_tile_without_block_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              Tile("rectangular", nx: 1, dx: 1, ny: 1, dy: 4, ix: "ix", iy: "iy", id: "ia")
            end
          end

          assert_match(/\b[Bb]lock\b.*\brequired/, error.message)
        end

        def test_tile_single
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g id="ia">
                <g id="iy-1">
                  <use id="ix-1-1" href="#rectangular"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            Tile("rectangular", nx: 1, dx: 1, ny: 1, dy: 4, ix: "ix", iy: "iy", id: "ia") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_multiple_with_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g id="ia">
                <g id="iy-1">
                  <use id="ix-1-1" href="#rectangular"/>
                  <use id="ix-1-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
                <g id="iy-2" transform="translate(0 4)">
                  <use id="ix-2-1" href="#rectangular"/>
                  <use id="ix-2-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
                <g id="iy-3" transform="translate(0 8)">
                  <use id="ix-3-1" href="#rectangular"/>
                  <use id="ix-3-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            Tile("rectangular", nx: 2, dx: 1, ny: 3, dy: 4, ix: "ix", iy: "iy", id: "ia") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_multiple_without_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g>
                <g id="iy-1">
                  <use id="ix-1-1" href="#rectangular"/>
                  <use id="ix-1-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
                <g id="iy-2" transform="translate(0 4)">
                  <use id="ix-2-1" href="#rectangular"/>
                  <use id="ix-2-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
                <g id="iy-3" transform="translate(0 8)">
                  <use id="ix-3-1" href="#rectangular"/>
                  <use id="ix-3-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            Tile("rectangular", nx: 2, dx: 1, ny: 3, dy: 4, ix: "ix", iy: "iy") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_multiple_with_column_ids
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g>
                <g>
                  <use id="ix-1-1" href="#rectangular"/>
                  <use id="ix-1-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
                <g transform="translate(0 4)">
                  <use id="ix-2-1" href="#rectangular"/>
                  <use id="ix-2-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
                <g transform="translate(0 8)">
                  <use id="ix-3-1" href="#rectangular"/>
                  <use id="ix-3-2" href="#rectangular" transform="translate(1 0)"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            Tile("rectangular", nx: 2, dx: 1, ny: 3, dy: 4, ix: "ix") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_multiple_without_any_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g>
                <g>
                  <use href="#rectangular"/>
                  <use href="#rectangular" transform="translate(1 0)"/>
                </g>
                <g transform="translate(0 4)">
                  <use href="#rectangular"/>
                  <use href="#rectangular" transform="translate(1 0)"/>
                </g>
                <g transform="translate(0 8)">
                  <use href="#rectangular"/>
                  <use href="#rectangular" transform="translate(1 0)"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            Tile("rectangular", nx: 2, dx: 1, ny: 3, dy: 4) do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end
      end

      class TileHTest < Minitest::Test
        DOC = :minimal

        def test_tile_h_zero_n_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              TileH("rectangular", n: 0, d: 4, i: "iy", id: "ia") do
                rect(width: 5, height: 8)
              end
            end
          end

          assert_match(/\bn\b.*\bpositive/, error.message)
        end

        def test_tile_h_without_block_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              TileH("rectangular", n: 1, d: 4, i: "iy", id: "ia")
            end
          end

          assert_match(/\b[Bb]lock\b.*\brequired/, error.message)
        end

        def test_tile_h_single
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g id="ia">
                <use id="iy-1" href="#rectangular"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            TileH("rectangular", n: 1, d: 4, i: "iy", id: "ia") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_h_multiple_with_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g id="ia">
                <use id="iy-1" href="#rectangular"/>
                <use id="iy-2" href="#rectangular" transform="translate(4 0)"/>
                <use id="iy-3" href="#rectangular" transform="translate(8 0)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            TileH("rectangular", n: 3, d: 4, i: "iy", id: "ia") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_h_multiple_without_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g>
                <use id="iy-1" href="#rectangular"/>
                <use id="iy-2" href="#rectangular" transform="translate(4 0)"/>
                <use id="iy-3" href="#rectangular" transform="translate(8 0)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            TileH("rectangular", n: 3, d: 4, i: "iy") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_h_multiple_without_any_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g>
                <use href="#rectangular"/>
                <use href="#rectangular" transform="translate(4 0)"/>
                <use href="#rectangular" transform="translate(8 0)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            TileH("rectangular", n: 3, d: 4) do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end
      end

      class TileVTest < Minitest::Test
        DOC = :minimal

        def test_tile_v_zero_n_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              TileV("rectangular", n: 0, d: 4, i: "ix", id: "ia") do
                rect(width: 5, height: 8)
              end
            end
          end

          assert_match(/\bn\b.*\bpositive/, error.message)
        end

        def test_tile_v_zero_without_block_raises_exception
          error = assert_raises(ArgumentError) do
            SVG DOC do
              TileV("rectangular", n: 1, d: 4, i: "ix", id: "ia")
            end
          end

          assert_match(/\b[Bb]lock\b.*\brequired/, error.message)
        end

        def test_tile_v_single
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g id="ia">
                <use id="ix-1" href="#rectangular"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            TileV("rectangular", n: 1, d: 4, i: "ix", id: "ia") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_v_multiple_with_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g id="ia">
                <use id="ix-1" href="#rectangular"/>
                <use id="ix-2" href="#rectangular" transform="translate(0 4)"/>
                <use id="ix-3" href="#rectangular" transform="translate(0 8)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            TileV("rectangular", n: 3, d: 4, i: "ix", id: "ia") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_v_multiple_without_main_group_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g>
                <use id="ix-1" href="#rectangular"/>
                <use id="ix-2" href="#rectangular" transform="translate(0 4)"/>
                <use id="ix-3" href="#rectangular" transform="translate(0 8)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            TileV("rectangular", n: 3, d: 4, i: "ix") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_tile_v_multiple_without_any_id
          expected = <<~SVG.chomp
            <svg>
              <symbol id="rectangular">
                <rect width="5" height="8"/>
              </symbol>
              <g>
                <use href="#rectangular"/>
                <use href="#rectangular" transform="translate(0 4)"/>
                <use href="#rectangular" transform="translate(0 8)"/>
              </g>
            </svg>
          SVG

          actual = SVG DOC do
            TileV("rectangular", n: 3, d: 4) do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end
      end
    end
  end
end
