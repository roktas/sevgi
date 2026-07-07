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
    end
  end
end
