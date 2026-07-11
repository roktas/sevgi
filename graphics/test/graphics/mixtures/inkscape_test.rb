# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class InkscapeTest < Minitest::Test
        Widget = ::Module.new do
          extend(Graphics::Module)

          def item(id)
            rect(id:)
          end
        end

        def test_layer_and_symbol_bang_render_inkscape_elements
          actual = SVG(:inkscape) do
            layer(id: "layer1") { rect(id: "rect") }
            symbol!(id: "glyph") { rect(width: 1) }
          end
            .Render()

          assert_match(/<g id="layer1" inkscape:groupmode="layer">/, actual)
          assert_match(/<g id="glyph" role="inkscape:symbol">/, actual)
        end

        def test_group_and_layer_default_to_module_name
          actual = SVG(:inkscape) do
            Group(Widget, "grouped")
            Layer(Widget, "layered")
            Layer!(Widget, "locked")
          end
            .Render()

          [
            %r{<g id="Widget">\n    <rect id="grouped"/>\n  </g>},
            %r{<g id="Widget" inkscape:groupmode="layer">\n    <rect id="layered"/>\n  </g>},
            %r{<g id="Widget" inkscape:groupmode="layer" sodipodi:insensitive="true">\n    <rect id="locked"/>\n  </g>}
          ].each { |pattern| assert_match(pattern, actual) }
        end

        def test_pages_yields_page_elements_to_block
          actual = SVG(:inkscape) do
            Pages({x: 1, y: 2, width: 3, height: 4}) do |page|
              page[:class] = "print"
            end
          end
            .Render()

          assert_match(%r{<inkscape:page id="page-1" x="1" y="2" width="3" height="4" class="print"/>}, actual)
        end

        def test_pages_tabular_positions_pages_by_width_and_height
          actual = SVG(:inkscape) do
            PagesTabular(rows: 2, cols: 2, width: 10, height: 20, gap: 5)
          end
            .Render()

          [
            /id="pageview-1x1" x="0" y="0"/,
            /id="pageview-1x2" x="15" y="0"/,
            /id="pageview-2x1" x="0" y="25"/,
            /id="pageview-2x2" x="15" y="25"/
          ].each { |pattern| assert_match(pattern, actual) }
        end

        def test_template_info_renders_optional_metadata
          actual = SVG(:inkscape) do
            InkscapeTemplateInfo(
              name: "Poster",
              desc: "Print layout",
              author: "Sevgi",
              date: "2026-07-07",
              keywords: %w[print poster]
            )
          end
            .Render()

          [
            %r{<inkscape:_name>Poster</inkscape:_name>},
            %r{<inkscape:_shortdesc>Print layout</inkscape:_shortdesc>},
            %r{<inkscape:date>2026-07-07</inkscape:date>},
            %r{<inkscape:author>Sevgi</inkscape:author>},
            %r{<inkscape:_keywords>print poster</inkscape:_keywords>}
          ].each { |pattern| assert_match(pattern, actual) }
        end
      end
    end
  end
end
