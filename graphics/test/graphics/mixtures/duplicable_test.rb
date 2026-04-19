# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class DuplicateTest < Minitest::Test
        def test_duplicate_doesnt_create_a_shallow_copy_of_attributes
          doc = SVG do
            line(id: "original", "data-var": "main var").Duplicate[:"data-var"] = "duplicated var"
          end

          [
            2,                doc.children.size,
            "original",       doc.children[0][:id],
            "main var",       doc.children[0][:"data-var"],
            "duplicated var", doc.children[1][:"data-var"]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_duplicate_deletes_id_attribute_by_default
          doc = SVG do
            line(id: "original", "data-var": "main var").Duplicate
          end

          assert_nil(doc.children[1][:id])
        end

        def test_duplicate_can_produce_new_id_attribute
          doc = SVG do
            line(id: "original", "data-var": "main var").Duplicate do |element|
              element[:id] = "#{element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"]}-copy" if element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"]
            end
          end

          assert_equal("original-copy", doc.children[1][:id])
        end

        def test_duplicate_doesnt_create_a_shallow_copy_of_children
          group1, group2 = Array.new(2)

          doc = SVG do
            group1 = g do
              line("data-var": "element1 of group1")
            end

            group2 = group1.Duplicate
            group2.children << nil

            group2.children.first[:"data-var"] = "element1 of group2"
          end

          [
            2, doc.children.size,
            1, doc.children[0].children.size,
            2, doc.children[1].children.size
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          assert_nil(doc.children[1].children.last)

          [
            "element1 of group1", group1.children.first[:"data-var"],
            "element1 of group2", group2.children.first[:"data-var"]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_duplicate_creates_new_object_ids
          ids = {}

          doc = SVG do
            group1 = g do
              ids[:element1] = line.object_id
              ids[:element2] = line.object_id
            end
            ids[:group1] = group1.object_id

            group2 = group1.Duplicate
            ids[:group2] = group2.object_id

            Within(group2) do
              ids[:element3] = line.object_id
            end
          end

          [
            2, doc.children.size,
            2, doc.children[0].children.size,
            3, doc.children[1].children.size
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          [
            ids.values_at(:group1, :group2),     doc.children.map(&:object_id),
            ids.values_at(:element1, :element2), doc.children[0].children.map(&:object_id),
            ids[:element3],                      doc.children[1].children.last.object_id
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          refute_equal(ids.values_at(:element1, :element2), doc.children[1].children.map(&:object_id).first(2))
        end

        def test_duplicate_conveniency_methods
          element1, element2, element3 = Array.new(3)

          doc = SVG do
            element1 = line
            element2 = element1.DuplicateX(1)
            element3 = element1.DuplicateY(1)
          end

          assert_nil(element1[:transform])

          [
            3,                doc.children.size,
            "translate(1 0)", element2[:transform],
            "translate(0 1)", element3[:transform]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end
      end
    end
  end
end
