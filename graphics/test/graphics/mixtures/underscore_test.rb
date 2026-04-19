# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class UnderscoreTest < Minitest::Test
        DOC = :minimal

        def test_underscore_text
          expected = <<~SVG.chomp
            <svg>
              <text>
                You are
                <tspan>not</tspan>
                a banana
              </text>
            </svg>
          SVG

          actual = SVG DOC do
            text do
              _ "You are"
              tspan "not"
              _ "a banana"
            end
          end.Render

          assert_equal(expected, actual)
        end

        def test_underscore_comment
          expected = <<~SVG.chomp
            <svg>
              <text>
                <!-- FOO -->
                You are
                <tspan>not</tspan>
                a banana
              </text>
            </svg>
          SVG

          actual = SVG DOC do
            text do
              Comment "FOO"
              _ "You are"
              tspan "not"
              _ "a banana"
            end
          end.Render

          assert_equal(expected, actual)
        end
      end
    end
  end
end
