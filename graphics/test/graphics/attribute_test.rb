# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Graphics
    class AttributeTest < Minitest::Test
      class MutableValue
        attr_reader :calls, :text

        def initialize(text)
          @calls = 0
          @text = text
        end

        def to_s
          @calls += 1
          text
        end
      end

      private_constant :MutableValue

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

      def test_import_owns_nested_attribute_values
        fill = +"red"
        token = +"token"
        nested = +"value"
        classes = [+"primary"]
        shared = [1, 2]
        custom = MutableValue.new(+"first")
        input = {
          style: {"fill" => fill, :meta => {token => nested}},
          class: classes,
          first: shared,
          second: shared,
          data: custom,
          count: 2,
          hidden: false,
          omitted: nil,
          shape: :round
        }
        attributes = Attributes.new(input)

        fill.replace("blue")
        token.replace("changed")
        nested.replace("changed")
        classes.first.replace("changed")
        shared << 3
        custom.text.replace("second")
        input.clear

        assert_equal({fill: "red", meta: {"token" => "value"}}, attributes[:style])
        assert_equal(["primary"], attributes[:class])
        assert_equal([1, 2], attributes[:first])
        assert_equal([1, 2], attributes[:second])
        assert_equal("first", attributes[:data])
        assert_equal([2, false, :round], attributes.to_h.values_at(:count, :hidden, :shape))
        refute(attributes.has?(:omitted))
        assert_equal(1, custom.calls)

        attributes[:style][:fill].replace("green")
        assert_equal("green", attributes[:style][:fill])
        assert_includes(
          attributes.to_xml_lines,
          "style=\"fill:green; meta:{&quot;token&quot; =&gt; &quot;value&quot;}\""
        )
        assert_equal(1, custom.calls)
      end

      def test_assignment_owns_nested_attribute_values
        fill = +"red"
        classes = [+"primary"]
        custom = MutableValue.new(+"first")
        attributes = Attributes.new

        attributes[:style] = {"fill" => fill}
        attributes[:class] = classes
        attributes[:data] = custom
        fill.replace("blue")
        classes.first.replace("changed")
        custom.text.replace("second")

        assert_equal({fill: "red"}, attributes[:style])
        assert_equal(["primary"], attributes[:class])
        assert_equal("first", attributes[:data])
        assert_equal(1, custom.calls)
      end

      def test_import_rejects_invalid_payload_atomically
        attributes = Attributes.new(fill: "red")
        cycle = []
        cycle << cycle
        bad_key = Object.new
        invalid = [
          -> { attributes.import([]) },
          -> { attributes.import("fill") },
          -> { attributes.import(fill: "blue", data: cycle) },
          -> { attributes.import("fill" => "blue", :fill => "green") },
          -> { attributes.import(style: {"fill" => "blue", :fill => "green"}) },
          -> { attributes.import(style: {meta: {"fill" => "blue", :fill => "green"}}) },
          -> { attributes.import(style: {bad_key => "blue"}) }
        ]

        invalid.each do |operation|
          assert_raises(Sevgi::ArgumentError, &operation)
          assert_equal({fill: "red"}, attributes.to_h)
        end
      end

      def test_assignment_rejects_invalid_payload_atomically
        attributes = Attributes.new(style: {fill: "red"})
        cycle = []
        cycle << cycle
        raising = Object.new.tap { it.define_singleton_method(:to_s) { raise "broken" } }
        wrong = Object.new.tap { it.define_singleton_method(:to_s) { Object.new } }
        invalid = [cycle, raising, wrong, {"fill" => "blue", :fill => "green"}]

        invalid.each do |value|
          assert_raises(Sevgi::ArgumentError) { attributes[:style] = value }
          assert_equal({fill: "red"}, attributes[:style])
        end
      end
    end
  end
end
