# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    class PaperTest < Minitest::Test
      def test_define_allows_profile_overwrite
        Paper.define(:paper_test_card, width: 3, height: 5)
        Paper.define(:paper_test_card, width: 7, height: 11)

        assert_equal([7.0, 11.0, :mm, :paper_test_card], Paper.paper_test_card.deconstruct)
      end

      def test_define_rejects_reserved_methods
        error = assert_raises(ArgumentError) do
          Paper.define(:define, width: 3, height: 5)
        end

        assert_match(/\breserved\b/, error.message)
        assert_instance_of(::Method, Paper.method(:define))
      end

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
