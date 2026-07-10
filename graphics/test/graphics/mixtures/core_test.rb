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

        def test_classify_normalizes_rendered_tokens
          element = SVG do
            rect(class: [:primary, "secondary tertiary"]).Classify(
              "primary",
              :secondary,
              "tertiary quaternary",
              %i[quaternary fifth]
            )
          end
            .children
            .first

          assert_equal(%w[primary secondary tertiary quaternary fifth], element[:class])
        end

        def test_classify_doesnt_mutate_caller_array
          classes = ["primary"]

          element = SVG do
            rect(class: classes).Classify("selected")
          end
            .children
            .first

          assert_equal(["primary"], classes)
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

        def test_adopt_moves_element_to_new_parent
          source = nil
          target = nil
          element = nil

          SVG(id: "main") do
            source = g(id: "source") { element = line(id: "line") }
            target = g(id: "target")
            element.Adopt(target)
          end

          [
            [],
            source.children,
            [element],
            target.children,
            target,
            element.parent
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_adopt_rejects_descendant_parent_atomically
          child = nil
          element = nil
          grandchild = nil

          doc = SVG(id: "main") do
            element = g(id: "element") do
              child = g(id: "child") do
                grandchild = line(id: "grandchild")
              end
            end
          end

          error = assert_raises(Sevgi::ArgumentError) { element.Adopt(grandchild) }

          assert_match(/descendant/i, error.message)

          [
            [element],
            doc.children,
            doc,
            element.parent,
            [child],
            element.children,
            element,
            child.parent,
            [grandchild],
            child.children,
            child,
            grandchild.parent
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_adopt_rejects_self_parent_atomically
          child = nil
          element = nil

          doc = SVG(id: "main") do
            element = g(id: "element") do
              child = line(id: "child")
            end
          end

          error = assert_raises(Sevgi::ArgumentError) { element.Adopt(element) }

          assert_match(/itself/i, error.message)

          [
            [element],
            doc.children,
            doc,
            element.parent,
            [child],
            element.children,
            element,
            child.parent
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_adopt_rejects_invalid_index_atomically
          source = nil
          target = nil
          element = nil

          SVG do
            source = g { element = line(id: "line") }
            target = g { line(id: "existing") }
          end

          ["bad", -3, 4].each do |index|
            error = assert_raises(Sevgi::ArgumentError) { element.Adopt(target, index:) }

            assert_match(/index/i, error.message)
            assert_equal([element], source.children)
            assert_equal(["existing"], target.children.map { it[:id] })
            assert_same(source, element.parent)
          end
        end

        def test_adopt_first_inserts_at_front
          target = nil
          element = nil

          SVG(id: "main") do
            target = g(id: "target") { line(id: "first") }
            element = line(id: "line")
            element.AdoptFirst(target)
          end

          assert_equal(%w[line first], target.children.map { it[:id] })
        end

        def test_orphan_removes_element_from_parent
          parent = nil
          element = nil

          SVG(id: "main") do
            parent = g(id: "parent") { element = line(id: "line") }
            element.Orphan()
          end

          assert_empty(parent.children)
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

        def test_traverse_can_stop_with_value
          doc = SVG(id: "main") do
            g { line(id: "target") }
          end

          found = doc.Traverse() { |element| element.Stay(element) if element[:id] == "target" }

          assert_equal("target", found[:id])
        end

        def test_stay_returns_public_stop_token
          doc = SVG(id: "main")
          token = doc.Stay(:done)

          assert_instance_of(Stop, token)
          assert_equal(:done, token.value)
        end

        def test_traverse_up_visits_ancestors
          descendant = nil

          SVG(id: "main") do
            g(id: "group") { descendant = line(id: "line") }
          end

          visited = []
          descendant.TraverseUp() { |element, height| visited << [height, element[:id]] }

          assert_equal([[0, "line"], [1, "group"], [2, "main"]], visited)
        end

        def test_with_executes_block_in_parent_context
          doc = SVG(id: "main") do
            group = g(id: "group")
            group.With() { line(id: "sibling") }
          end

          assert_equal(%w[group sibling], doc.children.map { it[:id] })
        end

        def test_within_executes_block_in_element_context
          doc = SVG(id: "main") do
            g(id: "group").Within() { line(id: "child") }
          end

          assert_equal(["child"], doc.children.first.children.map { it[:id] })
        end
      end
    end
  end
end
