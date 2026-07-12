# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class DuplicateTest < Minitest::Test
        def test_duplicate_doesnt_create_a_shallow_copy_of_attributes
          doc = SVG do
            line(id: "original", "data-var": "main var").Duplicate()[:"data-var"] = "duplicated var"
          end

          [
            2,
            doc.children.size,
            "original",
            doc.children[0][:id],
            "main var",
            doc.children[0][:"data-var"],
            "duplicated var",
            doc.children[1][:"data-var"]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_duplicate_deletes_id_attribute_by_default
          doc = SVG do
            line(id: "original", "data-var": "main var").Duplicate()
          end

          assert_nil(doc.children[1][:id])
        end

        def test_duplicate_can_produce_new_id_attribute
          doc = SVG do
            line(id: "original", "data-var": "main var").Duplicate() do |element|
              if element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"]
                element[:id] = "#{element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"]}-copy"
              end
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

            group2 = group1.Duplicate()
            group2.children << nil

            group2.children.first[:"data-var"] = "element1 of group2"
          end

          [
            2,
            doc.children.size,
            1,
            doc.children[0].children.size,
            2,
            doc.children[1].children.size
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          assert_nil(doc.children[1].children.last)

          [
            "element1 of group1",
            group1.children.first[:"data-var"],
            "element1 of group2",
            group2.children.first[:"data-var"]
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

            group2 = group1.Duplicate()
            ids[:group2] = group2.object_id

            Within(group2) do
              ids[:element3] = line.object_id
            end
          end

          [
            2,
            doc.children.size,
            2,
            doc.children[0].children.size,
            3,
            doc.children[1].children.size
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          [
            ids.values_at(:group1, :group2),
            doc.children.map(&:object_id),
            ids.values_at(:element1, :element2),
            doc.children[0].children.map(&:object_id),
            ids[:element3],
            doc.children[1].children.last.object_id
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          refute_equal(ids.values_at(:element1, :element2), doc.children[1].children.map(&:object_id).first(2))
        end

        def test_duplicate_reparents_copied_tree
          original = copy = nil

          doc = SVG do
            original = g(id: "original", class: ["main"], style: {fill: "red"}) do
              g(id: "branch") do
                text("label", id: "leaf")
              end
            end

            copy = original.Duplicate()
          end

          original_nodes = nodes(original)
          copy_nodes = nodes(copy)

          assert_equal(%i[g g text], copy_nodes.map(&:name))
          assert_same(doc, copy.parent)

          copy_nodes.drop(1).each do |node|
            assert_includes(copy_nodes, node.parent)
            refute_includes(original_nodes, node.parent)
          end

          copy[:class] << "copy"
          copy[:style][:fill] = "blue"

          [
            "original",
            original[:id],
            ["main"],
            original[:class],
            {fill: "red"},
            original[:style],
            [original.children.first],
            original.children,
            original,
            original.children.first.parent,
            original.children.first,
            original.children.first.children.first.parent
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_duplicate_copies_nested_attribute_and_content_payloads
          original = copy = nil

          SVG do
            original = g(style: {fill: ["red", {opacity: "1"}]}) do
              text(Content.verbatim(["original"]))
            end

            copy = original.Duplicate()
          end

          copy[:style][:fill] << "blue"
          copy[:style][:fill][1][:opacity] << "!"
          original_content = original.children.first.contents.first.content
          copy_content = copy.children.first.contents.first.content
          copy_content.first << " copy"

          assert_equal(["red", {opacity: "1"}], original[:style][:fill])
          assert_equal(["original"], original_content)
          assert_equal(["original"], original.children.first.contents.first.content)
          assert_equal(["original"], copy.children.first.contents.first.content)
          refute_same(original_content, copy_content)
          refute_same(original_content.first, copy_content.first)
        end

        def test_duplicate_rejects_cyclic_payloads
          content = []
          content << content

          rect = nil
          SVG do
            rect = self.rect(style: {})
          end

          rect[:style][:self] = rect[:style]

          assert_raises(Sevgi::ArgumentError) { rect.Duplicate() }
          assert_raises(Sevgi::ArgumentError) { Content.verbatim(content) }
        end

        def test_duplicate_copies_a_root_without_a_root_parent
          original = SVG { g { line } }

          copy = original.Duplicate()

          assert(copy.Root?())
          assert_same(copy, copy.Root())
          assert_equal(:svg, copy.name)
          assert_equal(1, copy.children.size)
        end

        def test_duplicate_operations_stay_in_copied_tree
          copy = copy_branch = copy_leaf = copy_sibling = nil
          original_branch = original_leaf = nil

          doc = SVG do
            original = g(id: "original") do
              original_branch = g(id: "branch") do
                original_leaf = line(id: "leaf")
              end
            end

            copy = original.Duplicate() do |element|
              id = element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"]
              element[:id] = "#{id}-copy" if id
            end

            copy_branch = copy.children.first
            copy_leaf = copy_branch.children.first
            copy_leaf.With() { copy_sibling = circle(id: "copy-sibling") }
            copy_leaf.Adopt(copy)
          end

          ancestors = []
          copy_leaf.TraverseUp() { |element| ancestors << element }

          assert_equal([original_leaf], original_branch.children)
          assert_equal([copy_sibling], copy_branch.children)
          assert_equal([copy_branch, copy_leaf], copy.children)
          assert_equal([copy_leaf, copy, doc], ancestors)

          [
            "original",
            doc.children.first[:id],
            "branch",
            original_branch[:id],
            "leaf",
            original_leaf[:id],
            "original-copy",
            copy[:id],
            "branch-copy",
            copy_branch[:id],
            "leaf-copy",
            copy_leaf[:id]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_duplicate_preserves_translation_axis
          source = SVG { rect }.children.first

          assert_nil(source.Duplicate()[:transform])
          assert_nil(source.Duplicate(dx: 0)[:transform])
          assert_nil(source.Duplicate(dy: 0)[:transform])

          [
            "translate(3)",
            source.Duplicate(dx: 3)[:transform],
            "translate(0 4)",
            source.Duplicate(dy: 4)[:transform],
            "translate(3 4)",
            source.Duplicate(dx: 3, dy: 4)[:transform]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_duplicate_copies_content_containers
          original = copy = nil

          SVG do
            original = text("original")
            copy = original.Duplicate()
            copy.contents << Content.encoded("copy")
          end

          refute_same(original.contents, copy.contents)

          [
            ["original"],
            original.contents.map(&:content),
            %w[original copy],
            copy.contents.map(&:content)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_duplicate_convenience_methods
          element1, element2, element3 = Array.new(3)

          doc = SVG do
            element1 = line
            element2 = element1.DuplicateX(1)
            element3 = element1.DuplicateY(1)
          end

          assert_nil(element1[:transform])

          [
            3,
            doc.children.size,
            "translate(1 0)",
            element2[:transform],
            "translate(0 1)",
            element3[:transform]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        private

        def nodes(element)
          [].tap { |result| element.Traverse() { |node| result << node } }
        end
      end
    end
  end
end
