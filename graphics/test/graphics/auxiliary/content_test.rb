# frozen_string_literal: true

require "nokogiri"

require_relative "../../test_helper"

module Sevgi
  module Graphics
    class ContentTest < Minitest::Test
      class MutableText
        attr_accessor :value
        attr_reader :calls

        def initialize(value)
          @value = value
          @calls = 0
        end

        def to_s
          @calls += 1
          value
        end
      end

      private_constant :MutableText

      def test_cdata_content_renders_block
        expected = <<~SVG
          <svg>
            <style>
              <![CDATA[
                a & b
                c < d
              ]]>
            </style>
          </svg>
        SVG
          .chomp

        actual = SVG(:minimal) do
          style(Content.cdata(["a & b", "c < d"]))
        end
          .Render()

        assert_equal(expected, actual)
      end

      def test_base_content_render_raises_panic_error
        assert_raises(PanicError) { Content.new("text").render(Object.new, 0) }
      end

      def test_encoded_and_verbatim_content_differ
        [
          "a &amp; b",
          Content.encoded("a & b").to_s,
          "a & b",
          Content.verbatim("a & b").to_s
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_encoded_content_stringifies_objects
        expected = <<~SVG
          <svg>
            <text>1 &amp; 2</text>
          </svg>
        SVG
          .chomp

        actual = SVG(:minimal) do
          text(Content.encoded(:"1 & 2"))
        end
          .Render()

        assert_render(expected, actual)
      end

      def test_cdata_splits_section_terminators
        actual = SVG(:minimal) do
          style(Content.cdata("a]]>b"))
        end
          .Render()

        assert_includes(actual, "]]]]><![CDATA[>")
        assert_equal("a]]>b", assert_render(actual, actual).at_css("style").text.strip)
      end

      def test_mixed_content_renders_valid_xml
        actual = SVG(:minimal) do
          text("1") do
            tspan(Content.encoded(:" & 2"))
          end
        end
          .Render()

        assert_render(actual, actual)
      end

      def test_content_rejects_xml_illegal_characters
        invalid = [
          "\u0000",
          "\u0001",
          "\u000B",
          "\u{FFFE}",
          "\xFF".dup.force_encoding("UTF-8")
        ]

        invalid.each do |value|
          invalid_content_operations(value).each do |operation|
            assert_raises(Sevgi::ArgumentError, &operation)
          end
        end
      end

      def test_content_owns_nested_payloads
        key = ["key"]
        value = +"value"
        object = MutableText.new("object")
        payload = {key => [value, {token: object}]}
        contents = [Content.new(payload), Content.cdata(payload), Content.encoded(payload), Content.verbatim(payload)]
        expected = {["key"] => ["value", {token: "object"}]}

        key << "caller"
        value << "\0"
        object.value = "\0"

        contents.each do |content|
          assert_equal(expected, content.content)

          reader = content.content
          values = reader.values.first
          reader.keys.first << "reader"
          values.first << " reader"
          values.last[:token] << " reader"

          assert_equal(expected, content.content)
        end

        assert_equal(4, object.calls)
      end

      def test_css_owns_stringified_rules
        selector = MutableText.new(".shape")
        property = MutableText.new("fill")
        value = MutableText.new("red")
        rules = {selector => {property => value}}
        content = Content.css(rules)

        rules.clear
        selector.value = property.value = value.value = "\0"

        assert_equal({".shape" => {"fill" => "red"}}, content.content)
        assert_equal([1, 1, 1], [selector.calls, property.calls, value.calls])

        reader = content.content
        reader[".shape"]["fill"] << " reader"
        assert_equal({".shape" => {"fill" => "red"}}, content.content)

        actual = SVG(:minimal) { style(content) }.Render()
        assert_includes(actual, ".shape {")
        assert_includes(actual, "fill: red;")
        assert_render(actual, actual)
      end

      def test_content_rejects_stringification_failures
        raising = Object.new.tap { it.define_singleton_method(:to_s) { raise "broken" } }
        wrong = Object.new.tap { it.define_singleton_method(:to_s) { Object.new } }

        [raising, wrong].each do |value|
          invalid_content_operations(value).each do |operation|
            assert_raises(Sevgi::ArgumentError, &operation)
          end
        end
      end

      def test_content_rejects_nested_cycles
        array = []
        array << array
        hash = {}
        hash[:self] = hash

        [array, hash].each do |value|
          [Content, Content::CData, Content::Encoded, Content::Verbatim].each do |klass|
            assert_raises(Sevgi::ArgumentError) { klass.new(value) }
          end
        end

        rules = {}
        rules[".shape"] = rules
        assert_raises(Sevgi::ArgumentError) { Content.css(rules) }
        assert_raises(Sevgi::ArgumentError) { Content.css(".shape" => {fill: array}) }
      end

      def test_content_rejects_snapshot_key_collisions
        left = MutableText.new("same")
        right = MutableText.new("same")
        payload = {left => "left", right => "right"}

        [Content, Content::CData, Content::Encoded, Content::Verbatim].each do |klass|
          assert_raises(Sevgi::ArgumentError) { klass.new(payload) }
        end

        assert_raises(Sevgi::ArgumentError) { Content.css(payload) }
      end

      def test_css_splits_cdata_terminators
        content = Content.css(".a]]>b" => {"fill]]>color" => "red]]>blue"})

        actual = SVG(:minimal) { style(content) }.Render()
        xml = assert_render(actual, actual)

        assert_equal(3, actual.scan("]]]]><![CDATA[>").size)
        assert_includes(xml.at_css("style").text, ".a]]>b {")
        assert_includes(xml.at_css("style").text, "fill]]>color: red]]>blue;")
      end

      def test_content_accepts_xml_whitespace_and_unicode
        value = "\t\n\r text 😀"

        actual = SVG(:minimal) { text(Content.encoded(value)) }.Render()

        assert_render("<svg>\n  <text>\t\n\r text 😀</text>\n</svg>", actual)
      end

      private

      def invalid_content_operations(value)
        [
          -> { Content.new(value) },
          -> { Content.encoded(value) },
          -> { Content.verbatim(value) },
          -> { Content.cdata(value) },
          -> { Content.css(value => "display") },
          -> { Content.css(".shape" => {value => "block"}) },
          -> { Content.css(".shape" => {display: value}) },
          -> { Content.css(".shape" => value) }
        ]
      end

      def assert_render(expected, actual)
        assert_equal(expected, actual)

        Nokogiri::XML(actual, &:strict)
      end
    end
  end
end
