# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    class NodeTest < Minitest::Test
      def test_usual_attributes
        svg = <<~SVG.chomp
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual   = Derender::Document.new(svg).decompile("xxx").attributes
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

        actual   = Derender::Document.new(svg).decompile("xxx")._
        expected = { "foo" => "fff", "bar" => "bbb" }

        assert_equal(expected, actual)
      end

      def test_find_default
        svg = <<~SVG.chomp
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual   = Derender::Document.new(svg).decompile().find("line1").derender

        expected = <<~SEVGI
          line id: "line1", length: 10.0
        SEVGI

        assert_equal(expected, actual)
      end

      def test_find_not_found
        svg = <<~SVG.chomp
          <g id="xxx" _:foo="fff" _:bar="bbb"/>
        SVG

        assert_nil(Derender::Document.new(svg).decompile().find("line1"))
      end

      def test_find_itself
        svg = <<~SVG.chomp
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual   = Derender::Document.new(svg).decompile().find("xxx").derender

        expected = <<~SEVGI
          g id: "xxx", "_:foo": "fff", "_:bar": "bbb" do
            line id: "line1", length: 10.0
            line id: "line2", length: 20.0
          end
        SEVGI

        assert_equal(expected, actual)
      end

      def test_find_by
        svg = <<~SVG.chomp
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG

        actual   = Derender::Document.new(svg).decompile().find("20.0", by: "length").derender

        expected = <<~SEVGI
          line id: "line2", length: 20.0
        SEVGI

        assert_equal(expected, actual)
      end
    end
  end
end
