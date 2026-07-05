# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    class NodeTest < Minitest::Test
      def test_attributes_keep_regular_and_custom_keys
        svg = <<~SVG
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Derender::Document.new(svg).decompile("xxx").attributes
        expected = {"id" => "xxx", "_:foo" => "fff", "_:bar" => "bbb"}

        assert_equal(expected, actual)
      end

      def test_custom_attributes_drop_namespace_prefix
        svg = <<~SVG
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Derender::Document.new(svg).decompile("xxx")._
        expected = {"foo" => "fff", "bar" => "bbb"}

        assert_equal(expected, actual)
      end

      def test_find_locates_node_by_id
        svg = <<~SVG
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Derender::Document.new(svg).decompile.find("line1").derender

        expected = <<~SEVGI
          line id: "line1", length: 10.0
        SEVGI

        assert_equal(expected, actual)
      end

      def test_find_returns_nil_for_missing_node
        svg = <<~SVG
          <g id="xxx" _:foo="fff" _:bar="bbb"/>
        SVG
          .chomp

        assert_nil(Derender::Document.new(svg).decompile.find("line1"))
      end

      def test_find_returns_root_node
        svg = <<~SVG
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Derender::Document.new(svg).decompile.find("xxx").derender

        expected = <<~SEVGI
          g id: "xxx", "_:foo": "fff", "_:bar": "bbb" do
            line id: "line1", length: 10.0
            line id: "line2", length: 20.0
          end
        SEVGI

        assert_equal(expected, actual)
      end

      def test_find_locates_node_by_attribute
        svg = <<~SVG
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Derender::Document.new(svg).decompile.find("20.0", by: "length").derender

        expected = <<~SEVGI
          line id: "line2", length: 20.0
        SEVGI

        assert_equal(expected, actual)
      end
    end
  end
end
