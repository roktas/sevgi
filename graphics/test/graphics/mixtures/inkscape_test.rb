# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class InkscapeTest < Minitest::Test
        Widget = ::Module.new do
          extend(Graphics::Module)

          def call(id)
            rect(id:)
          end
        end

        Forwarding = ::Module.new do
          extend(Graphics::Module)

          base { rect(id: "base") }

          def call(value, keyword:, &block)
            rect(id: "#{value}-#{keyword}-#{block.call}")
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

        def test_callable_wrappers_separate_and_forward_channels
          doc = SVG(:inkscape)
          wrappers = %i[Group Layer Layer!]
          results = wrappers.map do |wrapper|
            doc
              .public_send(
                wrapper,
                Forwarding,
                wrapper,
                keyword: "keyword",
                attributes: {id: wrapper, class: "container"}
              ) { "block" }
          end

          results.each_with_index do |container, index|
            assert_same(doc.children[index], container)
            assert_equal("container", container[:class])
            assert_equal(["base", "#{wrappers[index]}-keyword-block"], container.children.map { it[:id] })
          end

          assert_equal("true", results.last["sodipodi:insensitive"])
        end

        def test_pages_yields_page_elements_to_block
          doc = SVG(:inkscape)
          result = doc
            .Pages(
              {x: 1, y: 2, width: 3, height: 4, label: "front"},
              namedview: {id: "views", "data-view": "print"},
              page: {class: "sheet"}
            ) do |page|
              page[:class] = "print"
            end

          actual = doc.Render()

          assert_same(doc.children.first, result)
          assert_match(/<sodipodi:namedview id="views" data-view="print">/, actual)
          assert_match(
            %r{<inkscape:page id="page-1" class="print" x="1" y="2" width="3" height="4" label="front"/>},
            actual
          )
        end

        def test_pages_tabular_positions_pages_by_width_and_height
          doc = SVG(:inkscape)
          result = doc.PagesTabular(
            rows: 2,
            cols: 2,
            width: 10,
            height: 20,
            gap: 5,
            namedview: {id: "views"},
            page: {class: "sheet"}
          )
          actual = doc.Render()

          [
            /<sodipodi:namedview id="views">/,
            /id="pageview-1x1" class="sheet" x="0" y="0"/,
            /id="pageview-1x2" class="sheet" x="15" y="0"/,
            /id="pageview-2x1" class="sheet" x="0" y="25"/,
            /id="pageview-2x2" class="sheet" x="15" y="25"/,
            /class="sheet"/
          ].each { |pattern| assert_match(pattern, actual) }
          assert_same(doc.children.first, result)
        end

        def test_pages_rejects_invalid_inputs_atomically
          calls = [
            proc { |doc| doc.Pages(nil) },
            proc { |doc| doc.Pages({x: 0, y: 0, width: 1}) },
            proc { |doc| doc.Pages({x: "0", y: 0, width: 1, height: 1}) },
            proc { |doc| doc.Pages({x: 0, y: 0, width: 0, height: 1}) },
            proc { |doc| doc.Pages({:x => 0, :y => 0, :width => 1, :height => 1, :id => "a", "id" => "b"}) },
            proc { |doc| doc.Pages({x: 0, y: 0, width: 1, height: 1}, namedview: []) },
            proc { |doc| doc.Pages({x: 0, y: 0, width: 1, height: 1}, page: []) }
          ]

          calls.each do |call|
            doc = SVG(:inkscape)
            assert_raises(ArgumentError) { call.call(doc) }
            assert_empty(doc.children)
          end
        end

        def test_pages_tabular_rejects_invalid_inputs
          calls = [
            {rows: 0, cols: 1, width: 1, height: 1, gap: 0},
            {rows: 1, cols: 1.5, width: 1, height: 1, gap: 0},
            {rows: 1, cols: 1, width: 0, height: 1, gap: 0},
            {rows: 1, cols: 1, width: 1, height: Float::INFINITY, gap: 0},
            {rows: 1, cols: 1, width: 1, height: 1, gap: -1}
          ]

          calls.each do |arguments|
            doc = SVG(:inkscape)
            assert_raises(ArgumentError) { doc.PagesTabular(**arguments) }
            assert_empty(doc.children)
          end
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
