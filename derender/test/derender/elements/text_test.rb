# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Derender
    module Elements
      class TextTest < Minitest::Test
        def test_text
          expected = <<~SEVGI
            text do
              _ You are
              tspan "not", "font-weight": "bold"
              _ a banana
            end
          SEVGI

          svg = <<~SVG.chomp
            <text>
              You are
              <tspan font-weight="bold">not</tspan>
              a banana
            </text>
          SVG

          actual = Derender.derender(svg)

          assert_equal(expected, actual)
        end
      end
    end
  end
end
