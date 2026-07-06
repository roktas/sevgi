# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Derender
    module Elements
      class CSSTest < Minitest::Test
        def test_style_element_decompiles_to_css_call
          svg = <<~SVG
            <svg id="Root" shape-rendering="crispEdges" width="60.0mm" height="60.0mm" viewBox="0 0 60 60">
              <style type="text/css">
                <![CDATA[
                  * {
                    overflow: visible;
                  }
                  .code {
                    font-weight: 300;
                    font-size: 2.5px;
                    font-family: Operator Mono Lig;
                    letter-spacing: 0;
                    fill: #1a1a1a;
                    stroke-width: 0.264583;
                  }
                  #Tile {
                    stroke: #606060;
                    stroke-width: 0.32;
                    stroke-linejoin: round;
                    fill: darkgray;
                    fill-opacity: 0.4;
                  }
                ]]>
              </style>

              <defs id="Helpers">
                <clipPath id="Crop">
                  <rect width="60.0" height="60.0"/>
                </clipPath>
              </defs>
            </svg>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            SVG id: "Root", "shape-rendering": "crispEdges", width: "60.0mm", height: "60.0mm", viewBox: "0 0 60 60" do
              css({
                "*": {
                  "overflow": "visible",
                },
                ".code": {
                  "font-weight": 300,
                  "font-size": "2.5px",
                  "font-family": "Operator Mono Lig",
                  "letter-spacing": 0,
                  "fill": "#1a1a1a",
                  "stroke-width": 0.264583,
                },
                "#Tile": {
                  "stroke": "#606060",
                  "stroke-width": 0.32,
                  "stroke-linejoin": "round",
                  "fill": "darkgray",
                  "fill-opacity": 0.4,
                },
              })

              defs id: "Helpers" do
                clipPath id: "Crop" do
                  rect width: 60.0, height: 60.0
                end
              end
            end
          SEVGI

          assert_equal(expected, actual)
        end

        def test_css_ignores_empty_style_element
          svg = <<~SVG
            <svg id="Root" shape-rendering="crispEdges" width="60.0mm" height="60.0mm" viewBox="0 0 60 60">
              <style type="text/css"/>
            </svg>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            SVG id: "Root", "shape-rendering": "crispEdges", width: "60.0mm", height: "60.0mm", viewBox: "0 0 60 60" do
            end
          SEVGI

          assert_equal(expected, actual)
        end

        def test_css_escapes_quoted_selectors
          svg = <<~SVG
            <svg>
              <style>a[href="x"] { fill: red; }</style>
            </svg>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            SVG do
              css({
                "a[href=\\"x\\"]": {
                  "fill": "red",
                },
              })
            end
          SEVGI

          assert_equal(expected, actual)
        end
      end
    end
  end
end
