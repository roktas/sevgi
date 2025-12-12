# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    class NodeTest < Minitest::Test
      def test_all_attributes
        svg = <<~SVG.chomp
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual   = Derender.derender(svg, "xxx").attributes
        expected = { "id" => "xxx", "_:foo" => "fff", "_:bar" => "bbb" }

        assert_equal(expected, actual)
      end

      def test_custom_attributes
        svg = <<~SVG.chomp
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual   = Derender.derender(svg, "xxx")._
        expected = { "foo" => "fff", "bar" => "bbb" }

        assert_equal(expected, actual)
      end
    end
  end
end
