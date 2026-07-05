# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Graphics
    class AttributeTest < Minitest::Test
      def test_export_hides_internal_attributes
        attributes = Attributes.new(id: "visible", "-id": "hidden")

        [
          {id: "visible"},
          attributes.export,
          [:id],
          attributes.list
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_import_doesnt_mutate_nested_hash
        style = {"stroke-width" => 2}

        attributes = Attributes.new(style:)

        [
          [::String],
          style.keys.map(&:class),
          {style: {"stroke-width": 2}},
          attributes.to_h
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_update_suffix_merges_values
        attributes = Attributes.new(class: "primary", style: {stroke: "red"})

        attributes[:"class+"] = "selected"
        attributes[:"style+"] = {"stroke-width" => 2}

        [
          "primary selected",
          attributes[:class],
          {stroke: "red", "stroke-width": 2},
          attributes[:style]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_xml_escapes_array_and_hash_values
        attributes = Attributes.new(class: ["a&b", "c<d"], style: {content: "a & b"})

        assert_equal(
          [
            "class=\"a&amp;b c&lt;d\"",
            "style=\"content:a &amp; b\""
          ],
          attributes.to_xml_lines
        )
      end
    end
  end
end
