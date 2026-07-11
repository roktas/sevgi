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

      def test_import_doesnt_alias_array_values
        classes = ["primary"]
        attributes = Attributes.new(class: classes)

        classes << "caller"
        attributes[:class] << "store"

        [
          %w[primary caller],
          classes,
          %w[primary store],
          attributes[:class]
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

      def test_xml_rejects_invalid_attribute_values
        invalid = ["illegal\0value", "\xFF".b]

        invalid.each do |value|
          error = assert_raises(Sevgi::ArgumentError) { Attributes.new(fill: value) }

          assert_match(/XML attribute value/i, error.message)
        end
      end

      def test_xml_rejects_cyclic_attribute_values
        array = []
        array << array
        hash = {}
        hash[:self] = hash

        [array, hash].each do |value|
          error = assert_raises(Sevgi::ArgumentError) { Attributes.new(data: value) }

          assert_match(/cyclic XML attribute value/i, error.message)
        end
      end

      def test_xml_rejects_invalid_attribute_names
        ["", "bad name", "1bad", "bad:name:again", "\xFF".b].each do |name|
          error = assert_raises(Sevgi::ArgumentError) { Attributes.new(name => "value") }

          assert_match(/XML attribute name/i, error.message)
        end
      end

      def test_xml_revalidates_mutated_attribute_values
        attributes = Attributes.new(fill: +"red", class: ["shape"])
        attributes[:fill].replace("illegal\0value")
        attributes[:class] << attributes[:class]

        assert_raises(Sevgi::ArgumentError) { attributes.to_xml_lines }
      end

      def test_xml_preserves_namespaces_and_unicode
        attributes = Attributes.new("xml:lang": "tr", "veri-çeşidi": "kar\u{0131}\u{015f}\u{0131}k & parlak")

        assert_equal(
          [
            "xml:lang=\"tr\"",
            "veri-çeşidi=\"karışık &amp; parlak\""
          ],
          attributes.to_xml_lines
        )
      end
    end
  end
end
