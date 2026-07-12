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
        [[3.0, 90.0], LengthAngle.new(length: 3.0, angle: 90.0)].each do |tallness|
          parallelogram = Parallelogram.new_by_height(
            horizontal: [4.0, 0.0],
            tallness:,
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
      end

      def test_parallelogram_new_by_width_preserves_wideness
        [[4.0, 0.0], LengthAngle.new(length: 4.0, angle: 0.0)].each do |wideness|
          parallelogram = Parallelogram.new_by_width(
            vertical: [3.0, 90.0],
            wideness:,
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

      def test_parallelogram_rejects_infeasible_constraints
        [
          /height is smaller/,
          -> { Parallelogram.new_by_height(horizontal: [2, 90], tallness: [1, 45]) },
          /height angle must have a vertical component/,
          -> { Parallelogram.new_by_height(horizontal: [2, 0], tallness: [3, 0]) },
          /width is smaller/,
          -> { Parallelogram.new_by_width(vertical: [2, 0], wideness: [1, 45]) },
          /width angle must have a horizontal component/,
          -> { Parallelogram.new_by_width(vertical: [2, 90], wideness: [3, 90]) }
        ].each_slice(2) do |message, operation|
          error = assert_raises(Error, &operation)

          assert_match(message, error.message)
        end
      end
    end
  end
end
