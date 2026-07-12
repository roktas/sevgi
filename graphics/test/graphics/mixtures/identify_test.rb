# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class IdentifyTest < Minitest::Test
        def test_identifiers_report_id_collisions
          doc = SVG(:minimal) do
            g(id: "same") { line(id: "line") }
            rect(id: "same")
          end

          identifiers = doc.Identifiers()

          [
            true,
            identifiers.conflict?,
            :g,
            identifiers["same"].name,
            %i[g rect],
            identifiers.collision["same"].map(&:name),
            :line,
            identifiers["line"].name
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_identifiers_use_serialized_id_values
          doc = SVG(:minimal) do
            text(id: nil)
            g(id: :same)
            rect(id: "same")
            circle(id: false)
            path(id: "false")
            line(id: 0)
            ellipse(id: "0")
            polyline(id: "")
            polygon(id: "")
          end

          identifiers = doc.Identifiers()

          [
            true,
            identifiers.conflict?,
            %i[g rect],
            identifiers.collision["same"].map(&:name),
            %i[circle path],
            identifiers.collision["false"].map(&:name),
            %i[line ellipse],
            identifiers.collision["0"].map(&:name),
            %i[polyline polygon],
            identifiers.collision[""].map(&:name)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          refute(doc.children.first.attributes.has?(:id))
          refute_includes(identifiers.namespace, "nil")
          assert_nil(identifiers[nil])
        end

        def test_identifiers_are_immutable_snapshots
          doc = SVG(:minimal) do
            g(id: "same")
            rect(id: "same")
          end

          identifiers = doc.Identifiers()

          assert_raises(FrozenError) { identifiers.namespace.clear }
          assert_raises(FrozenError) { identifiers.collision.clear }
          assert_raises(FrozenError) { identifiers.collision["same"] << doc }
          assert_raises(::ArgumentError) { identifiers["same", "other"] }

          first = identifiers["same"]
          first[:id] = "changed"
          doc.circle(id: "later")

          assert_same(first, identifiers["same"])
          assert_nil(identifiers["changed"])
          assert_nil(identifiers["later"])
          assert_same(first, doc.Identifiers()["changed"])
          assert_predicate(identifiers.namespace.keys.first, :frozen?)
        end

        def test_disidentify_hides_visible_ids
          doc = SVG(:minimal) do
            g(id: "group", "-id": "group-source") do
              line(id: "line", "-id": "line-source")
              circle(id: false)
            end
          end

          doc.Disidentify()
          group = doc.children.first
          line, circle = group.children

          assert_nil(group[:id])
          assert_nil(line[:id])
          assert_nil(circle[:id])

          [
            "group-source",
            group[:"-id"],
            "line-source",
            line[:"-id"],
            false,
            circle[:"-id"]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          refute_match(/\bid=/, doc.Render())
        end
      end
    end
  end
end
