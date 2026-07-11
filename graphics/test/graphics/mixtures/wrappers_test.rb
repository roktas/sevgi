# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class WrappersTest < Minitest::Test
        DOC = :minimal

        def test_line_wrappers_build_path_commands
          expected = <<~SVG
            <svg>
              <path id="line-to" d="M 0 0 L 1 2"/>
              <path id="hline-to" d="M 0 0 H 3"/>
              <path id="vline-to" d="M 0 0 V 4"/>
              <path id="line-by" d="M 0 0 l 5.0 0.0"/>
              <path id="relh" d="M 0 0 h 5"/>
              <path id="relv" d="M 0 0 v 6"/>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            LineTo(id: "line-to", x2: 1, y2: 2)
            HLineTo(id: "hline-to", x2: 3)
            VLineTo(id: "vline-to", y2: 4)
            LineBy(id: "line-by", angle: 0, length: 5)
            HLineBy(id: "relh", length: 5)
            VLineBy(id: "relv", length: 6)
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_shape_and_symbol_wrappers_build_elements
          expected = <<~SVG
            <svg>
              <rect id="box" width="7" height="7"/>
              <symbol id="alert-icon">
                <title>Alert Icon</title>
                <rect width="1"/>
              </symbol>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            square(id: "box", length: 7)
            Symbol("Alert Icon") { rect(width: 1) }
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_css_wrapper_renders_cdata_style
          expected = <<~SVG
            <svg>
              <style type="text/css">
                <![CDATA[
                  rect {
                    fill: red;
                  }
                ]]>
              </style>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            css(rect: {fill: "red"})
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_css_wrapper_accepts_style_attributes
          actual = SVG(DOC) do
            css({rect: {fill: "red"}}, id: "main-style")
          end
            .Render()

          assert_match(%r{<style id="main-style" type="text/css">}, actual)
        end

        def test_css_wrapper_rejects_malformed_styles
          doc = SVG(DOC)
          error = assert_raises(ArgumentError) { doc.css(rect: Object.new) }

          assert_match(/\bMalformed style\b/, error.message)
          assert_empty(doc.children)
        end
      end
    end
  end
end
