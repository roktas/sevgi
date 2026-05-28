# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class RenderTest < Minitest::Test
        DOC = :minimal

        def test_render_text_element_with_simple_string
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

        def test_render_text_element_with_spaced_string
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

          assert_equal(expected, actual)
        end

        def test_render_text_element_with_special_string
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

          assert_equal(expected, actual)
        end

        def test_render_text_element_with_raw_string
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

        def test_render_inline_content_element_with_simple_string
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

          assert_equal(expected, actual)
        end

        def test_render_inline_content_element_with_long_attribute
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

          assert_equal(expected, actual)
        end
      end
    end
  end
end
