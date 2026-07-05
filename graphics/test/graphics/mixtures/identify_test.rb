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

        def test_disidentify_hides_visible_ids
          doc = SVG(:minimal) do
            g(id: "group") { line(id: "line") }
          end

          doc.Disidentify()
          group = doc.children.first
          line = group.children.first

          assert_nil(group[:id])
          assert_nil(line[:id])

          [
            "group",
            group[:"-id"],
            "line",
            line[:"-id"]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

          refute_match(/\bid=/, doc.Render())
        end
      end
    end
  end
end
