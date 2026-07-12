# frozen_string_literal: true

require "nokogiri"

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class RenderTest < Minitest::Test
        DOC = :minimal

        def test_render_text_element_encodes_plain_string
          expected = <<~SVG
            <svg>
              <text>foo bar</text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text("foo bar")
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_render_text_element_preserves_spacing
          expected = <<~SVG
            <svg>
              <text>   foo  bar </text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text("   foo  bar ")
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_text_element_preserves_xml_space
          expected = <<~SVG
            <svg>
              <text xml:space="preserve"> foo </text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text(" foo ", "xml:space": "preserve")
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_text_element_escapes_special_characters
          expected = <<~SVG
            <svg>
              <text>foo &amp; bar</text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text("foo & bar")
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_text_element_preserves_verbatim_content
          expected = <<~SVG
            <svg>
              <text>foo & bar</text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text(Content.verbatim("foo & bar"))
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_render_foreign_style_preserves_inline_text
          expected = <<~SVG
            <svg>
              <group xmlns="urn:foreign">
                <style xml:space="preserve">  raw style  </style>
              </group>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            Element(:group, xmlns: "urn:foreign") do
              style("  raw style  ", "xml:space": "preserve")
            end
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_inline_content_element_encodes_plain_string
          expected = <<~SVG
            <svg>
              <title>foo bar</title>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            title("foo bar")
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_inline_content_element_wraps_long_attribute
          attribute = "x" * 140

          expected = <<~SVG
            <svg>
              <title
                id="#{attribute}"
              >foo bar</title>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            title("foo bar", id: attribute)
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_mixed_inline_text_with_one_tspan
          expected = <<~SVG
            <svg>
              <text>foo<tspan>bar</tspan></text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text("foo") do
              tspan("bar")
            end
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_mixed_inline_text_with_multiple_tspans
          expected = <<~SVG
            <svg>
              <text>foo<tspan>bar</tspan><tspan>baz</tspan></text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text("foo") do
              tspan("bar")
              tspan("baz")
            end
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_mixed_inline_text_with_trailing_text
          expected = <<~SVG
            <svg>
              <text>foo<tspan>bar</tspan>baz</text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text("foo") do
              tspan("bar")
              _("baz")
            end
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_mixed_inline_text_with_multiple_contents
          expected = <<~SVG
            <svg>
              <text>foo&amp;bar<tspan>baz</tspan></text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text("foo", Content.encoded("&bar")) do
              tspan("baz")
            end
          end
            .Render()

          assert_render(expected, actual)
          assert_equal("foo&barbaz", Nokogiri::XML(actual).at_xpath("//text").text)
        end

        def test_render_mixed_inline_text_with_nested_tspans
          expected = <<~SVG
            <svg>
              <text>foo<tspan>bar<tspan>baz</tspan></tspan></text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text("foo") do
              tspan("bar") do
                tspan("baz")
              end
            end
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_mixed_inline_text_preserves_xml_space
          expected = <<~SVG
            <svg>
              <text xml:space="preserve"> foo <tspan> bar </tspan></text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text(" foo ", "xml:space": "preserve") do
              tspan(" bar ")
            end
          end
            .Render()

          assert_render(expected, actual)
        end

        def test_render_block_style_splits_attributes
          expected = <<~SVG
            <svg>
              <rect
                id="box"
                width="1"
                height="2"
              />
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            rect(id: "box", width: 1, height: 2)
          end
            .Render(style: :block)

          assert_render(expected, actual)
        end

        def test_render_inline_style_keeps_attributes_inline
          expected = <<~SVG
            <svg>
              <rect id="box" width="1" height="2"/>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            rect(id: "box", width: 1, height: 2)
          end
            .Render(style: :inline)

          assert_render(expected, actual)
        end

        def test_render_rejects_unrecognized_style
          error = assert_raises(ArgumentError) { SVG(DOC).Render(style: :unknown) }

          assert_match(/\bunknown\b/, error.message)
        end

        def test_render_validates_formatting_options
          document = SVG(DOC) { rect }
          invalid = [
            {indent: "text"},
            {indent: "illegal\0indent"},
            {indent: 2},
            {linelength: -1},
            {linelength: 1.5},
            {validate: false},
            {unknown: true}
          ]

          invalid.each do |options|
            assert_raises(Sevgi::ArgumentError) { document.Render(**options) }
          end

          assert_render("<svg>\n\t<rect/>\n</svg>", document.Render(indent: "\t", linelength: 0))
        end

        def test_render_children_returns_empty_fragments
          %i[default minimal html inkscape].each do |profile|
            assert_equal("", SVG(profile).RenderChildren())
          end
        end

        def test_render_children_validates_options_when_empty
          document = SVG(DOC)

          [{style: :unknown}, {indent: "text"}, {linelength: -1}, {unknown: true}].each do |options|
            assert_raises(Sevgi::ArgumentError) { document.RenderChildren(**options) }
          end
        end

        def test_render_children_joins_top_level_children
          doc = SVG(DOC) do
            rect(id: "one")
            circle(id: "two")
          end

          assert_render("<rect id=\"one\"/>\n\n<circle id=\"two\"/>", doc.RenderChildren(), fragment: true)
        end

        def test_render_children_forwards_renderer_options
          doc = SVG(DOC) do
            g(id: "one") { rect(id: "child") }
            circle(id: "two")
          end

          actual = doc.RenderChildren("\n", style: :block, indent: "\t", linelength: 0)
          expected = <<~SVG
            <g
            \tid="one"
            >
            \t<rect
            \t\tid="child"
            \t/>
            </g>
            <circle
            \tid="two"
            />
          SVG
            .chomp

          assert_render(expected, actual, fragment: true)
        end

        def test_render_children_validates_separator
          document = SVG(DOC) do
            rect
            circle
          end

          ["illegal\0separator", "\xFF".b, Object.new].each do |separator|
            assert_raises(Sevgi::ArgumentError) { document.RenderChildren(separator) }
          end

          actual = document.RenderChildren("\n<!-- split -->\n")
          assert_render("<rect/>\n<!-- split -->\n<circle/>", actual, fragment: true)
        end

        def test_render_children_omits_document_preambles
          %i[default minimal html inkscape].each do |profile|
            actual = SVG(profile) { rect }.RenderChildren()

            assert_render("<rect/>", actual, fragment: true)
            refute_includes(actual, "<?xml")
          end
        end

        def test_render_children_omits_preambles_for_multiple_children
          %i[default minimal html inkscape].each do |profile|
            actual = SVG(profile) do
              rect
              circle
            end
              .RenderChildren()

            assert_render("<rect/>\n\n<circle/>", actual, fragment: true)
            refute_includes(actual, "<?xml")
          end
        end

        private

        def assert_render(expected, actual, fragment: false)
          assert_equal(expected, actual)
          xml = fragment ? "<wrapper>#{actual}</wrapper>" : actual

          Nokogiri::XML(xml, &:strict)
        end
      end
    end
  end
end
