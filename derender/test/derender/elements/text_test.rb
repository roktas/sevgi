# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Derender
    module Elements
      class TextTest < Minitest::Test
        def test_text_element_preserves_inline_text_and_tspan
          expected = <<~SEVGI
            text do
              _ "You are"
              tspan "not", "font-weight": "bold"
              _ "a banana"
            end
          SEVGI

          svg = <<~SVG
            <text>
              You are
              <tspan font-weight="bold">not</tspan>
              a banana
            </text>
          SVG
            .chomp

          actual = Derender.derender(svg)

          assert_equal(expected, actual)
        end

        def test_text_child_preserves_inline_boundary_spaces
          svg = <<~SVG
            <text>A <tspan>B</tspan> C</text>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            text do
              _ "A "
              tspan "B"
              _ " C"
            end
          SEVGI

          assert_equal(expected, actual)
        end

        def test_text_child_preserves_inline_space_between_elements
          svg = <<~SVG
            <text><tspan>A</tspan> <tspan>B</tspan></text>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            text do
              tspan "A"
              _ " "
              tspan "B"
            end
          SEVGI

          assert_equal(expected, actual)
        end

        def test_text_element_decompiles_plain_content
          svg = <<~SVG
            <text>You are</text>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            text "You are"
          SEVGI

          assert_equal(expected, actual)
        end

        def test_text_element_evaluates_plain_content
          svg = <<~SVG
            <text>You are</text>
          SVG
            .chomp

          actual = Derender.evaluate(svg, SVG(:minimal)).Render()

          assert_equal("<text>You are</text>", actual)
        end

        def test_text_element_preserves_xml_space_content
          svg = <<~SVG
            <text xml:space="preserve">  a   b  </text>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            text "  a   b  ", "xml:space": "preserve"
          SEVGI

          assert_equal(expected, actual)
        end

        def test_text_child_preserves_xml_space_content
          svg = <<~SVG
            <text xml:space="preserve">  You <tspan>are</tspan> here  </text>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            text "xml:space": "preserve" do
              _ "  You "
              tspan "are"
              _ " here  "
            end
          SEVGI

          assert_equal(expected, actual)
        end

        def test_text_child_preserves_blank_nodes
          svg = <<~SVG
            <text xml:space="preserve">  <tspan>x</tspan>  </text>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            text "xml:space": "preserve" do
              _ "  "
              tspan "x"
              _ "  "
            end
          SEVGI

          assert_equal(expected, actual)
        end
      end
    end
  end
end
