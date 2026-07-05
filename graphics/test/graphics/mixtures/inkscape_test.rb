# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class InkscapeTest < Minitest::Test
        def test_layer_and_symbol_bang_render_inkscape_elements
          actual = SVG(:inkscape) do
            layer(id: "layer1") { rect(id: "rect") }
            symbol!(id: "glyph") { rect(width: 1) }
          end
            .Render(validate: false)

          assert_match(/<g id="layer1" inkscape:groupmode="layer">/, actual)
          assert_match(/<g id="glyph" role="inkscape:symbol">/, actual)
        end

        def test_pages_tabular_positions_pages_by_width_and_height
          actual = SVG(:inkscape) do
            PagesTabular(rows: 2, cols: 2, width: 10, height: 20, gap: 5)
          end
            .Render(validate: false)

          [
            /id="pageview-1x1" x="0" y="0"/,
            /id="pageview-1x2" x="15" y="0"/,
            /id="pageview-2x1" x="0" y="25"/,
            /id="pageview-2x2" x="15" y="25"/
          ].each { |pattern| assert_match(pattern, actual) }
        end
      end
    end
  end
end
