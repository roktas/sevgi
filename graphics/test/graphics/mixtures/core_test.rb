# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class CoreTreeTest < Minitest::Test
        def test_tree_construction_basics
          doc = SVG id: "main" do
            g = g(id: "group1") { line(id: "line1") }
            line2 = line(id: "line2")
            g << line2
          end

          [
            1, doc.children.size,
            2, doc.children[0].children.size,
            0, doc.children[0].children[0].children.size
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          [
            "main",   doc[:id],
            "group1", doc.children[0][:id],
            "line1",  doc.children[0].children[0][:id],
            "line2",  doc.children[0].children[1][:id]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_prepend_method_actually_prepends
          doc = SVG id: "main" do
            g = g(id: "group1") { line(id: "line1") }
            line2 = line(id: "line2")
            g.Prepend(line2)
          end

          [
            1, doc.children.size,
            2, doc.children[0].children.size,
            0, doc.children[0].children[0].children.size
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          [
            "main",   doc[:id],
            "group1", doc.children[0][:id],
            "line2",  doc.children[0].children[0][:id],
            "line1",  doc.children[0].children[1][:id]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end
      end
    end
  end
end
