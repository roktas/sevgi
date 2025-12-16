# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    class DerenderTest < Minitest::Test
      def test_derender_only
        expected = <<~SEVGI
          g id: "xxx" do
            line id: "line1", length: 10.0
            line id: "line2", length: 20.0
          end
        SEVGI

        svg = <<~SVG.chomp
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual = Derender.derender(svg, id: "xxx")

        assert_equal(expected, actual)
      end

      def test_evaluate
        expected = svg = <<~SVG.chomp
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual = Derender.evaluate(svg, SVG(:minimal), id: "xxx").Render

        assert_equal(expected, actual)
      end

      def test_evaluate_bang
        svg = <<~SVG.chomp
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        expected = <<~SVG.chomp
          <svg>
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </svg>
        SVG

        actual = SVG :minimal do
          Derender.evaluate!(svg, self, id: "xxx")
        end.Render

        assert_equal(expected, actual)
      end
    end
  end
end
