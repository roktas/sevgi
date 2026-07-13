# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    class AttributesTest < Minitest::Test
      def test_flat_attributes_decompile_as_keywords
        hash = {"foo" => "fff", "b ar" => "bbb"}

        actual = Attributes.decompile(hash)
        expected = "foo: \"fff\", \"b ar\": \"bbb\""

        assert_equal(expected, actual)
      end

      def test_nested_attributes_decompile_as_hash_literal
        hash = {"foo" => "fff", "b ar" => "bbb", "baz" => {"qu ux" => 19, "bat" => "b a t "}}

        actual = Attributes.decompile(hash)
        expected = "foo: \"fff\", \"b ar\": \"bbb\", baz: { \"qu ux\": 19, bat: \"b a t \" }"

        assert_equal(expected, actual)
      end

      def test_style_attribute_decompiles_as_hash_literal
        hash = {"foo" => "fff", "style" => "color: red; display: none"}

        actual = Attributes.decompile(hash)
        expected = "foo: \"fff\", style: { color: \"red\", display: \"none\" }"

        assert_equal(expected, actual)
      end

      def test_style_attribute_decompiles_empty_declarations
        hash = {"style" => ""}

        actual = Attributes.decompile(hash)

        assert_equal("style: {}", actual)
      end

      def test_style_attribute_preserves_lossy_declarations_as_source
        [
          "display: -webkit-box; display: grid",
          "--Tone: red; color: var(--Tone)",
          "malformed"
        ].each do |style|
          assert_equal("style: #{style.inspect}", Attributes.decompile("style" => style))
        end
      end

      def test_decompile_doesnt_mutate_input_hash
        hash = {"style" => "color: red", "id" => "root", "class" => "main"}

        Attributes.decompile(hash)

        assert_equal({"style" => "color: red", "id" => "root", "class" => "main"}, hash)
      end

      def test_string_attributes_escape_quotes
        hash = {"label" => "A \"quoted\" value"}

        actual = Attributes.decompile(hash)
        expected = "label: \"A \\\"quoted\\\" value\""

        assert_equal(expected, actual)
      end

      def test_attribute_keys_escape_quotes
        hash = {"a\"b" => "quoted", "c\\d" => "backslash"}

        actual = Attributes.decompile(hash)
        expected = "\"a\\\"b\": \"quoted\", \"c\\\\d\": \"backslash\""

        assert_equal(expected, actual)
      end

      def test_key_order_prioritizes_id_class_and_style
        hash = {
          "foo" => "fff",
          "inkscape:label" => "label",
          "id" => "bbb",
          "baz" => 19,
          "class" => "ccc",
          "style" => "color: red; display: none",
          "hmm" => "hhh"
        }

        actual = Attributes.decompile(hash)
        expected = "id: \"bbb\", \"inkscape:label\": \"label\", class: \"ccc\", foo: \"fff\", baz: 19, hmm: \"hhh\", style: { color: \"red\", display: \"none\" }"

        assert_equal(expected, actual)
      end
    end
  end
end
