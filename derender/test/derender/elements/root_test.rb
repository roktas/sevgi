# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Derender
    module Elements
      class RootTest < Minitest::Test
        def test_root_decompiles_svg_tree
          svg = <<~SVG
            <svg id="Root" shape-rendering="crispEdges" width="60.0mm" height="60.0mm" viewBox="0 0 60 60">
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
              defs id: "Helpers" do
                clipPath id: "Crop" do
                  rect width: 60.0, height: 60.0
                end
              end
            end
          SEVGI

          assert_equal(expected, actual)
        end

        def test_root_preserves_namespace_attributes
          svg = <<~SVG
            <svg
              id="Root"
              xmlns="http://www.w3.org/2000/svg"
              xmlns:_="http://sevgi.roktas.dev"
              shape-rendering="crispEdges"
              width="60.0mm"
              height="60.0mm"
              viewBox="0 0 60 60"
            >
              <defs id="Helpers">
                <clipPath id="Crop" _:width="10.0">
                  <rect width="60.0" height="60.0"/>
                </clipPath>
              </defs>
            </svg>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            SVG id: "Root", xmlns: "http://www.w3.org/2000/svg", "xmlns:_": "http://sevgi.roktas.dev", "shape-rendering": "crispEdges", width: "60.0mm", height: "60.0mm", viewBox: "0 0 60 60" do
              defs id: "Helpers" do
                clipPath id: "Crop", "_:width": 10.0 do
                  rect width: 60.0, height: 60.0
                end
              end
            end
          SEVGI

          assert_equal(expected, actual)
        end

        def test_root_emits_document_preambles
          svg = <<~SVG
            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <svg
              id="Root"
              xmlns="http://www.w3.org/2000/svg"
              xmlns:_="http://sevgi.roktas.dev"
              shape-rendering="crispEdges"
              width="60.0mm"
              height="60.0mm"
              viewBox="0 0 60 60"
            >
              <defs id="Helpers">
                <clipPath id="Crop" _:width="10.0">
                  <rect width="60.0" height="60.0"/>
                </clipPath>
              </defs>
            </svg>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            SVG.Document preambles: [
              "<?xml version=\\"1.0\\" encoding=\\"UTF-8\\" standalone=\\"no\\"?>",
            ]

            SVG id: "Root", xmlns: "http://www.w3.org/2000/svg", "xmlns:_": "http://sevgi.roktas.dev", "shape-rendering": "crispEdges", width: "60.0mm", height: "60.0mm", viewBox: "0 0 60 60" do
              defs id: "Helpers" do
                clipPath id: "Crop", "_:width": 10.0 do
                  rect width: 60.0, height: 60.0
                end
              end
            end
          SEVGI

          assert_equal(expected, actual)
        end

        def test_root_escapes_document_preambles
          svg = <<~SVG
            <?xml version="1.0"?>
            <?app value="a'b"?>
            <svg/>
          SVG
            .chomp

          actual = Derender.derender(svg)

          expected = <<~SEVGI
            SVG.Document preambles: [
              "<?xml version=\\"1.0\\"?>",
              "<?app value=\\"a'b\\"?>",
            ]

            SVG
          SEVGI

          assert_equal(expected, actual)
        end
      end
    end
  end
end
