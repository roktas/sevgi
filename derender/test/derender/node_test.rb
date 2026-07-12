# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    class NodeTest < Minitest::Test
      def test_node_owns_immutable_public_state
        node = Derender.decompile("<svg xmlns=\"urn:test\" id=\"root\"><g id=\"child\"/></svg>")

        [node, node.attributes, node.namespaces, node.meta, node.children, node.content, node.name].each do |value|
          assert_predicate(value, :frozen?)
        end

        [*node.attributes, *node.namespaces, *node.meta].flatten.each { assert_predicate(it, :frozen?) }
        assert_predicate(node.children.first, :frozen?)
      end

      def test_node_hides_parser_and_strategy_plumbing
        node = Derender.decompile("<svg/>")

        assert_raises(NameError) { Derender::Document }
        refute_respond_to(Node, :new)
        %i[node type pres decompile attributes!].each { refute_respond_to(node, it) }
        assert_empty(Derender.public_instance_methods(false))
      end

      def test_dispatch_respects_namespace_and_conversion_root
        cases = {
          "<style>.a { fill: red; }</style>" => :CSS,
          "<style xmlns=\"http://www.w3.org/2000/svg\">.a { fill: red; }</style>" => :CSS,
          "<s:style xmlns:s=\"http://www.w3.org/2000/svg\"/>" => :Any,
          "<f:style xmlns:f=\"urn:foreign\"/>" => :Any,
          "<style xmlns=\"urn:foreign\"/>" => :Any,
          "<svg/>" => :Root,
          "<svg xmlns=\"http://www.w3.org/2000/svg\"/>" => :Root,
          "<s:svg xmlns:s=\"http://www.w3.org/2000/svg\"/>" => :Any,
          "<f:svg xmlns:f=\"urn:foreign\"/>" => :Any,
          "<svg xmlns=\"urn:foreign\"/>" => :Any
        }

        cases.each do |xml, type|
          assert_equal(type, Document.new(xml).decompile.send(:type), xml)
        end

        xml = "<svg xmlns=\"http://www.w3.org/2000/svg\"><svg id=\"nested\"/></svg>"
        root = Document.new(xml).decompile

        assert_equal(:Any, root.children.first.send(:type))
        assert_equal(:Root, Document.new(xml).decompile("nested").send(:type))

        foreign_style = Document.new("<style xmlns=\"urn:foreign\">raw</style>").decompile.derender
        foreign_svg = Document.new("<svg xmlns=\"urn:foreign\"/>").decompile.derender

        assert_match(/\AElement\(:"style",/, foreign_style)
        assert_match(/\AElement\(:"svg",/, foreign_svg)
      end

      def test_attributes_keep_regular_and_custom_keys
        svg = <<~SVG
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Document.new(svg).decompile("xxx").attributes
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

        actual = Document.new(svg).decompile("xxx")._
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

        actual = Document.new(svg).decompile.find("line1").derender

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

        assert_nil(Document.new(svg).decompile.find("line1"))
      end

      def test_find_returns_root_node
        svg = <<~SVG
          <g id="xxx" _:foo="fff" _:bar="bbb">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Document.new(svg).decompile.find("xxx").derender

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

        actual = Document.new(svg).decompile.find("20.0", by: "length").derender

        expected = <<~SEVGI
          line id: "line2", length: 20.0
        SEVGI

        assert_equal(expected, actual)
      end
    end
  end
end
