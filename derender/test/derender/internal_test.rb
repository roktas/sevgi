# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    class CssTest < Minitest::Test
      def test_css_to_h_parses_rule_blocks
        string = <<~STRING
          * {
          overflow: visible;
          }
          .code {
            font-weight: 300;
            font-size: 2.5px;
            font-family: Operator Mono Lig;
            letter-spacing: 0;
            fill: #1a1a1a;
            stroke-width: 0.264583;
          }
          #Tile {
            stroke: #606060;
            stroke-width: 0.32;
            stroke-linejoin: round;
            fill: darkgray;
            fill-opacity: 0.4;
          }
        STRING
          .chomp

        actual = Css.to_h(string)

        expected = {
          "*" => {
            "overflow" => "visible"
          },
          ".code" => {
            "font-weight" => "300",
            "font-size" => "2.5px",
            "font-family" => "Operator Mono Lig",
            "letter-spacing" => "0",
            "fill" => "#1a1a1a",
            "stroke-width" => "0.264583"
          },
          "#Tile" => {
            "stroke" => "#606060",
            "stroke-width" => "0.32",
            "stroke-linejoin" => "round",
            "fill" => "darkgray",
            "fill-opacity" => "0.4"
          }
        }

        assert_equal(expected, actual)
      end

      def test_css_to_h_bang_parses_declarations
        string = <<~STRING
          stroke: #606060; stroke-width: 0.32; stroke-linejoin: round; fill: darkgray; fill-opacity: 0.4;
        STRING
          .chomp

        actual = Css.to_h!(string)

        expected = {
          "stroke" => "#606060",
          "stroke-width" => "0.32",
          "stroke-linejoin" => "round",
          "fill" => "darkgray",
          "fill-opacity" => "0.4"
        }

        assert_equal(expected, actual)
      end

      def test_rules_accepts_only_lossless_hash_conversions
        assert_equal({".mark" => {"fill" => "red"}}, Css.rules(".mark { fill: red; }"))

        [
          "@media print { .mark { fill: black; } }",
          ".mark { display: block; display: grid; }",
          ".mark { --Tone: red; }",
          ".mark { malformed }"
        ].each { assert_nil(Css.rules(it)) }
      end

      def test_declarations_accepts_only_lossless_hash_conversions
        assert_equal({"fill" => "red"}, Css.declarations("fill: red"))
        assert_equal({}, Css.declarations(""))

        [
          "display: block; display: grid",
          "--Tone: red",
          "malformed"
        ].each { assert_nil(Css.declarations(it)) }
      end

      def test_to_key_keeps_plain_key
        %w[
          foo
          foo
        ].each_slice(2) do |key, expected|
          actual = Css.to_key(key)

          assert_equal(expected, actual)
        end
      end

      def test_to_value_quotes_non_numeric_values
        [
          "10",
          "10",
          "10.3",
          "10.3",
          "foo bar",
          "\"foo bar\""
        ].each_slice(2) do |value, expected|
          actual = Css.to_value(value)

          assert_equal(expected, actual)
        end
      end

      def test_to_key_value_formats_pair
        [
          "foo",
          "bar baz",
          "\"foo\": \"bar baz\"",
          "a\"b",
          "quoted",
          "\"a\\\"b\": \"quoted\""
        ].each_slice(3) do |key, value, expected|
          actual = Css.to_key_value(key, value)

          assert_equal(expected, actual)
        end
      end

      def test_bare_element_ignores_cached_element_dispatch_methods
        SVG(:minimal) { rect }

        assert(Ruby.bare_element?(:rect))
      end

      def test_bare_element_rejects_redefined_cached_dispatch_methods
        SVG(:minimal) { rect }
        Element.remove_method(:rect)
        Element.define_method(:rect) { raise "application method" }

        refute(Ruby.bare_element?(:rect))
      ensure
        Element.remove_method(:rect) if Element.method_defined?(:rect)
      end
    end

    class RubyTest < Minitest::Test
      def test_ruby_format_formats_code
        string = <<~STRING
          if i==0
          nil
          end
        STRING
          .chomp

        actual = Ruby.format(string)

        expected = <<~STRING
          if i == 0
            nil
          end
        STRING

        assert_equal(expected, actual)
      end

      def test_ruby_format_raises_panic_error
        string = "if"

        error = assert_raises(PanicError) { Ruby.format(string) }

        assert_equal(string, error.message)
      end
    end
  end
end
