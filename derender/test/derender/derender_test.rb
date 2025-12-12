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


        actual = Derender.derender(svg, "xxx").render

        assert_equal(expected, actual)
      end

      def test_derender_render_include_current_true
        expected = xml = <<~SVG.chomp
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual = Derender.derender(xml, "xxx").(SVG(:minimal)).Render

        assert_equal(expected, actual)
      end

      def test_derender_render_include_current_false
        xml = <<~SVG.chomp
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
          Derender.derender(xml, "xxx").(self, false)
        end.Render

        assert_equal(expected, actual)
      end
    end
  end
end
