# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Standard
    class ColorTest < Minitest::Test
      def test_color_valid_accepts_named_color_and_rejects_unknown
        assert(Color.valid?("limegreen"))
        assert(Color.valid?("Red"))
        assert(Color.valid?(:Red))
        refute(Color.valid?("frobnicate"))
        refute(Color.valid?(nil))
        refute(Color.valid?(Object.new))
      end

      def test_color_hex_resolves_named_color
        assert_equal("#FFFACD", Color[:lemonchiffon])
        assert_equal("#FFFACD", Color["LemonChiffon"])
        assert_equal("#FF0000", Color[:Red])
        assert_equal(Color[:lemonchiffon], Color.lemonchiffon)
        assert_equal("#663399", Color[:rebeccapurple])
        assert(Color.valid?(:rebeccapurple))
        assert_nil(Color[nil])
        assert_nil(Color[Object.new])
      end
    end
  end
end
