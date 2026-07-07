# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class ParallelogramTest < Minitest::Test
      def test_parallelogram_exposes_side_lengths
        parallelogram = Parallelogram[
          [2.0, -15.0],
          [5.0, -F.atan2(4.0, 3.0)]
        ]

        [
          2.0,
          parallelogram.AB.length,
          5.0,
          parallelogram.BC.length,
          2.0,
          parallelogram.CD.length,
          5.0,
          parallelogram.DA.length
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_parallelogram_new_by_height_preserves_tallness
        parallelogram = Parallelogram.new_by_height(
          horizontal: [4.0, 0.0],
          tallness: [3.0, 90.0],
          position: [1.0, 2.0]
        )

        [
          Point[1, 2],
          parallelogram.position,
          4.0,
          parallelogram.AB.length,
          3.0,
          parallelogram.BC.length,
          3.0,
          parallelogram.box.height
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_parallelogram_new_by_width_preserves_wideness
        parallelogram = Parallelogram.new_by_width(
          vertical: [3.0, 90.0],
          wideness: [4.0, 0.0],
          position: [1.0, 2.0]
        )

        [
          Point[1, 2],
          parallelogram.position,
          4.0,
          parallelogram.AB.length,
          3.0,
          parallelogram.BC.length,
          4.0,
          F.approx(parallelogram.box.width)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
