# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class CoreTreeTest < Minitest::Test
        def test_classify_appends_to_string_attribute
          element = SVG do
            rect(class: "primary").Classify("selected", "primary")
          end
            .children
            .first

          assert_equal(%w[primary selected], element[:class])
        end

        def test_defaults_preserves_false_attribute
          element = SVG do
            rect(hidden: false).Defaults(hidden: true)
          end
            .children
            .first

          assert_equal(false, element[:hidden])
        end

        def test_tree_construction_appends_children
          doc = SVG(id: "main") do
            g = g(id: "group1") { line(id: "line1") }
            line2 = line(id: "line2")
            g << line2
          end

          [
            1,
            doc.children.size,
            2,
            doc.children[0].children.size,
            0,
            doc.children[0].children[0].children.size
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          [
            "main",
            doc[:id],
            "group1",
            doc.children[0][:id],
            "line1",
            doc.children[0].children[0][:id],
            "line2",
            doc.children[0].children[1][:id]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_prepend_method_actually_prepends
          doc = SVG(id: "main") do
            g = g(id: "group1") { line(id: "line1") }
            line2 = line(id: "line2")
            g.Prepend(line2)
          end

          [
            1,
            doc.children.size,
            2,
            doc.children[0].children.size,
            0,
            doc.children[0].children[0].children.size
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          [
            "main",
            doc[:id],
            "group1",
            doc.children[0][:id],
            "line2",
            doc.children[0].children[0][:id],
            "line1",
            doc.children[0].children[1][:id]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_root_returns_document_root_from_descendant
          descendant = nil

          doc = SVG(id: "main") do
            g { descendant = line(id: "line1") }
          end

          assert_same(doc, descendant.Root())
        end
      end
    end
  end
end
