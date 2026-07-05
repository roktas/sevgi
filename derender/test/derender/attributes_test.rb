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
