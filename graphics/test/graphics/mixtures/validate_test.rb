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
      end
    end
  end
end
