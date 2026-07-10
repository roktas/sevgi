# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    class MarginTest < Minitest::Test
      def test_margin_axis_totals_and_adjust
        margin = Margin[1, 2, 3, 4]

        [
          6.0,
          margin.horizontal,
          4.0,
          margin.vertical,
          [6.0, 5.0, 8.0, 7.0],
          margin.adjust(3, 5).to_a
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_margin_expands_css_like_values
        [
          [0.0, 0.0, 0.0, 0.0],
          Margin.margin(nil).to_a,
          [1.0, 1.0, 1.0, 1.0],
          Margin.margin([1]).to_a,
          [1.0, 2.0, 1.0, 2.0],
          Margin.margin([1, 2]).to_a,
          [1.0, 2.0, 3.0, 2.0],
          Margin.margin([1, 2, 3]).to_a,
          [1.0, 2.0, 3.0, 4.0],
          Margin.margin([1, 2, 3, 4]).to_a
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
