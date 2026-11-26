# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class ValidateTest < Minitest::Test
        def test_cdata_joins_text_contents
          element = nil

          SVG(:minimal) do
            element = text("alpha", "beta")
          end

          assert_equal("alpha\nbeta", element.CData())
        end

        def test_ns_detects_profile_and_ancestor_namespaces
          child = nil
          descendant = nil

          doc = SVG(:inkscape) do
            child = g("xmlns:foo": "https://example.test/foo") do
              descendant = rect
            end
          end

          [
            true,
            doc.NS?(:inkscape),
            true,
            child.NS?(:inkscape),
            true,
            descendant.NS?(:foo),
            false,
            descendant.NS?(:missing)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          doc.attributes.delete(:"xmlns:inkscape")

          [
            false,
            doc.NS?(:inkscape),
            false,
            child.NS?(:inkscape),
            false,
            descendant.NS?(:inkscape)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_validate_rejects_invalid_attributes
          error = assert_raises(InvalidAttributesError) do
            SVG(:minimal) { rect(foo: "bar") }.()
          end

          assert_match(/\bfoo\b/, error.message)
        end

        def test_validate_can_be_disabled_for_call
          actual = SVG(:minimal) { rect(foo: "bar") }.(validate: false)

          assert_match(/foo="bar"/, actual)
        end

        def test_validate_applies_svg_rules_by_namespace_inside_foreign_object
          drawing = SVG do
            foreignObject(width: 100, height: 30) do
              Element(:div, xmlns: "http://www.w3.org/1999/xhtml") do
                g("xmlns:vector": "http://www.w3.org/2000/svg") do
                  Element(:"vector:rect", width: 1)
                end
              end
            end
          end

          assert_includes(drawing.call, "<vector:rect")

          drawing.foreignObject do
            Element(:div, xmlns: "http://www.w3.org/1999/xhtml") do
              g(xmlns: "http://www.w3.org/2000/svg") { rect(unknown: true) }
            end
          end

          assert_raises(InvalidAttributesError) { drawing.call }
        end

        def test_qualified_root_keeps_children_without_a_default_namespace
          root = Document::Minimal.element(:"s:svg", {"xmlns:s": "http://www.w3.org/2000/svg"}) do
            Element(:"s:foreignObject") { Element(:label, "Plain") }
          end

          assert(root.Root?())
          assert_includes(root.call, "<label>Plain</label>")
          assert_same(root.children.first, root.children.first.Validate())
        end
      end
    end
  end
end
