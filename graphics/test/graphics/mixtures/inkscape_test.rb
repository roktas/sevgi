# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class InkscapeTest < Minitest::Test
        DOC = :inkscape

        def test_inkscape_extension_with_tile
          expected = <<~SVG.chomp
            <?xml version="1.0" standalone="no"?>
            <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
              xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
              xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
              shape-rendering="crispEdges"
              width="210.0mm"
              height="297.0mm"
              viewBox="0 0 210 297"
            >
              <defs>
                <g id="rectangular" role="inkscape:symbol">
                  <rect width="5" height="8"/>
                </g>
              </defs>
              <g id="ia" inkscape:groupmode="layer" sodipodi:insensitive="true">
                <g id="iy-1" inkscape:groupmode="layer" sodipodi:insensitive="true">
                  <use id="ix-1-1" xlink:href="#rectangular"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC, :a4 do
            Tile("rectangular", nx: 1, dx: 1, ny: 1, dy: 4, ix: "ix", iy: "iy", id: "ia") do
              rect(width: 5, height: 8)
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_inkscape_extension_with_replicate
          expected = <<~SVG.chomp
            <?xml version="1.0" standalone="no"?>
            <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
              xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
              xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
              shape-rendering="crispEdges"
              width="210.0mm"
              height="297.0mm"
              viewBox="0 0 210 297"
            >
              <g id="ia" inkscape:groupmode="layer" sodipodi:insensitive="true">
                <g id="iy-1" inkscape:groupmode="layer" sodipodi:insensitive="true">
                  <rect id="ix-1-1" width="5" height="8"/>
                </g>
              </g>
            </svg>
          SVG

          actual = SVG DOC, :a4 do
            rect(width: 5, height: 8).Replicate(nx: 1, dx: 1, ny: 1, dy: 4, ix: "ix", iy: "iy", id: "ia")
          end.Render

          assert_equal(expected, actual)
        end
      end
    end
  end
end
