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
      end
    end
  end
end
