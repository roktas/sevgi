# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Standard
    class ColorTest < Minitest::Test
      def test_color_valid
        assert(Color.valid?("limegreen"))
        refute(Color.valid?("frobnicate"))
      end

      def test_color_hex
        assert_equal("#FFFACD", Color[:lemonchiffon])
        assert_equal(Color[:lemonchiffon], Color.lemonchiffon)
      end
    end
  end
end
