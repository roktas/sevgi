# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    class PaperTest < Minitest::Test
      def test_iso_a_profiles_use_standard_small_sizes
        [
          [74.0, 105.0, :mm, :a7],
          Paper.a7.deconstruct,
          [52.0, 74.0, :mm, :a8],
          Paper.a8.deconstruct,
          [37.0, 52.0, :mm, :a9],
          Paper.a9.deconstruct,
          [26.0, 37.0, :mm, :a10],
          Paper.a10.deconstruct
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
