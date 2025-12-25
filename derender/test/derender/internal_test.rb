# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    class CssTest < Minitest::Test
      def test_css_to_h
        string = <<~'STRING'.chomp
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

        actual = Css.to_h(string)

        expected = {
          "*"     => {
            "overflow" => "visible"
          },
          ".code" => {
            "font-weight"    => "300",
            "font-size"      => "2.5px",
            "font-family"    => "Operator Mono Lig",
            "letter-spacing" => "0",
            "fill"           => "#1a1a1a",
            "stroke-width"   => "0.264583"
          },
          "#Tile" => {
            "stroke"          => "#606060",
            "stroke-width"    => "0.32",
            "stroke-linejoin" => "round",
            "fill"            => "darkgray",
            "fill-opacity"    => "0.4"
          }
        }

        assert_equal(expected, actual)
      end

      def test_css_to_h!
        string = <<~'STRING'.chomp
          stroke: #606060; stroke-width: 0.32; stroke-linejoin: round; fill: darkgray; fill-opacity: 0.4;
        STRING

        actual = Css.to_h!(string)

        expected = {
          "stroke"          => "#606060",
          "stroke-width"    => "0.32",
          "stroke-linejoin" => "round",
          "fill"            => "darkgray",
          "fill-opacity"    => "0.4"
        }

        assert_equal(expected, actual)
      end

      def test_to_key
        [
          "foo", "foo"
        ].each_slice(2) do |key, expected|
          actual   = Css.to_key(key)

          assert_equal(expected, actual)
        end
      end

      def test_to_value
        [
          "10",      "10",
          "10.3",    "10.3",
          "foo bar", '"foo bar"',
        ].each_slice(2) do |value, expected|
          actual   = Css.to_value(value)

          assert_equal(expected, actual)
        end
      end

      def test_to_key_value
        [
          "foo", "bar baz", '"foo": "bar baz"',
        ].each_slice(3) do |key, value, expected|
          actual   = Css.to_key_value(key, value)

          assert_equal(expected, actual)
        end
      end
    end

    class RubyTest < Minitest::Test
      def test_ruby_format
        string = <<~'STRING'.chomp
          if i==0
          nil
          end
        STRING

        actual = Ruby.format(string)

        expected = <<~'STRING'
          if i == 0
            nil
          end
        STRING

        assert_equal(expected, actual)
      end
    end
  end
end
