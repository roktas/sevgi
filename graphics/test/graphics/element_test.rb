# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Graphics
    class Element
      class ElementInstanceTest < Minitest::Test
        def test_element_construction_without_block
          root = Element.send(:new, :g, parent: Element::RootParent, attributes: {"data-var": 42}, contents: ["foo"])

          [
            :g,
            root.name,
            Element::RootParent,
            root.parent,
            [],
            root.children,
            {"data-var": 42},
            root.attributes.to_h,
            ["foo"],
            root.contents.map(&:to_s),
            true,
            Element.root?(root)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          child = Element.send(:new, :"missing-glyph", parent: root, attributes: {id: "glyph"})

          [
            :"missing-glyph",
            child.name,
            root,
            child.parent,
            [],
            child.children,
            {id: "glyph"},
            child.attributes.to_h,
            false,
            Element.root?(child),
            [child],
            root.children
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_element_construction_with_block
          child = nil
          root = Element.send(:new, :g, parent: Element::RootParent, attributes: {"data-var": 42}) do
            child = missing_glyph(id: "glyph")
          end

          [
            :g,
            root.name,
            Element::RootParent,
            root.parent,
            [child],
            root.children,
            {"data-var": 42},
            root.attributes.to_h,
            true,
            Element.root?(root),
            :"missing-glyph",
            child.name,
            root,
            child.parent,
            [],
            child.children,
            {id: "glyph"},
            child.attributes.to_h,
            false,
            Element.root?(child)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end
      end

      class ElementClassTest < Minitest::Test
        def test_arguments_parse_accepts_empty_input
          parsed = Dispatch.parse(:svg)

          [
            {},
            parsed[:attributes],
            [],
            parsed[:contents]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          assert_raises(ArgumentError) { Dispatch.parse(:svg, ["foo"]) }
        end

        def test_arguments_parse_splits_text_and_attributes
          parsed = Dispatch.parse(:svg, "foo", "bar & baz", x: 19, y: 42)

          [
            {x: 19, y: 42},
            parsed[:attributes],
            [Content::Encoded, Content::Encoded],
            parsed[:contents].map(&:class),
            ["foo", "bar &amp; baz"],
            parsed[:contents].map(&:to_s)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_arguments_parse_preserves_content_objects
          parsed = Dispatch.parse(:svg, Content::Verbatim.new("bar & baz"))

          [
            [Content::Verbatim],
            parsed[:contents].map(&:class),
            ["bar & baz"],
            parsed[:contents].map(&:to_s)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_root_builds_svg_parent_and_children
          child = nil
          root = Element.root("data-var": 42) do
            child = missing_glyph(id: "glyph")
          end

          [
            :svg,
            root.name,
            Element::RootParent,
            root.parent,
            [child],
            root.children,
            {"data-var": 42},
            root.attributes.to_h,
            true,
            Element.root?(root),
            :"missing-glyph",
            child.name,
            root,
            child.parent,
            [],
            child.children,
            {id: "glyph"},
            child.attributes.to_h,
            false,
            Element.root?(child)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end
      end

      class ElementMethodMissingTest < Minitest::Test
        def setup = %i[svg marker].each { Element.remove_method(it) if Element.method_defined?(it) }

        def teardown = setup

        def test_respond_to_accepts_svg_element_names
          assert_respond_to(Element.root, :marker)
        end

        def test_invalid_element_name_raises_exception
          assert_raises(NameError) { Element.root { foobar } }
        end

        def test_method_missing_caches_nested_element_methods
          refute(Element.method_defined?(:svg))
          refute(Element.method_defined?(:marker))

          test = self

          Element.root do
            svg do
              test.assert(Element.method_defined?(:svg))
              test.refute(Element.method_defined?(:marker))

              marker

              test.assert(Element.method_defined?(:svg))
              test.assert(Element.method_defined?(:marker))
            end
          end

          assert(Element.method_defined?(:svg))
          assert(Element.method_defined?(:marker))
        end

        def test_subclass_method_missing_caching_affects_parent
          refute(Element.method_defined?(:svg))
          refute(Element.method_defined?(:marker))

          subclass = Class.new(Element)

          test = self

          subclass.root do
            svg do
              test.assert(subclass.method_defined?(:svg))
              test.refute(subclass.method_defined?(:marker))

              test.assert(Element.method_defined?(:svg))
              test.refute(Element.method_defined?(:marker))

              marker

              test.assert(subclass.method_defined?(:svg))
              test.assert(subclass.method_defined?(:marker))

              test.assert(Element.method_defined?(:svg))
              test.assert(Element.method_defined?(:marker))
            end
          end

          assert(subclass.method_defined?(:svg))
          assert(subclass.method_defined?(:marker))

          assert(Element.method_defined?(:svg))
          assert(Element.method_defined?(:marker))
        end

        def test_root_element_construction_doesnt_define_an_svg_method
          refute(Element.method_defined?(:svg))
          refute(Element.method_defined?(:marker))

          test = self

          Element.root do
            test.refute(Element.method_defined?(:marker))

            marker

            test.assert(Element.method_defined?(:marker))
          end

          refute(Element.method_defined?(:svg))
          assert(Element.method_defined?(:marker))
        end
      end
    end
  end
end
