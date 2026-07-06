# frozen_string_literal: true

require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Derender
    class DerenderTest < Minitest::Test
      def test_derender_converts_selected_node_to_dsl
        expected = <<~SEVGI
          g id: "xxx" do
            line id: "line1", length: 10.0
            line id: "line2", length: 20.0
            text do
              _ "You are"
              tspan "not", "font-weight": "bold"
              _ "a banana"
            end
          end
        SEVGI

        svg = <<~SVG
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
            <text>
              You are
              <tspan font-weight="bold">not</tspan>
              a banana
            </text>
          </g>
        SVG
          .chomp

        actual = Derender.derender(svg, id: "xxx")

        assert_equal(expected, actual)
      end

      def test_evaluate_renders_selected_node_in_document
        expected = svg = <<~SVG
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Derender.evaluate(svg, SVG(:minimal), id: "xxx").Render()

        assert_equal(expected, actual)
      end

      def test_evaluate_bang_appends_selected_node_to_document
        svg = <<~SVG
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        expected = <<~SVG
          <svg>
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </svg>
        SVG
          .chomp

        actual = SVG(:minimal) do
          Derender.evaluate!(svg, self, id: "xxx")
        end
          .Render()

        assert_equal(expected, actual)
      end

      def test_derender_file_converts_selected_node
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "source.svg")
          ::File.write(
            file,
            <<~SVG
              <g id="xxx">
                <line id="line1" length="10.0"/>
              </g>
            SVG
              .chomp
          )

          actual = Derender.derender_file(file, id: "xxx")

          expected = <<~SEVGI
            g id: "xxx" do
              line id: "line1", length: 10.0
            end
          SEVGI

          assert_equal(expected, actual)
        end
      end

      def test_evaluate_file_bang_appends_selected_children
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "source.svg")
          ::File.write(
            file,
            <<~SVG
              <g id="xxx">
                <line id="line1" length="10.0"/>
                <line id="line2" length="20.0"/>
              </g>
            SVG
              .chomp
          )

          actual = SVG(:minimal) do
            Derender.evaluate_file!(file, self, id: "xxx")
          end
            .Render()

          expected = <<~SVG
            <svg>
              <line id="line1" length="10.0"/>
              <line id="line2" length="20.0"/>
            </svg>
          SVG
            .chomp

          assert_equal(expected, actual)
        end
      end
    end
  end
end
