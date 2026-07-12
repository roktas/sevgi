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

      def test_parallelogram_rejects_unrelated_points
        assert_raises(Error) { Parallelogram.from_points([0, 0], [2, 0], [3, 1], [0, 1]) }
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

      def test_height_constraint_preserves_signed_direction
        [-30, 30, 150, 210, 330, 390].each do |angle|
          [
            [3, angle],
            LengthAngle.new(length: 3, angle:)
          ].each do |constraint|
            parallelogram = Parallelogram.new_by_height(
              horizontal: [4, 0],
              tallness: constraint,
              position: [1, 2]
            )

            assert_equal(Point[1, 2], parallelogram.position)
            assert_equal(angle.to_f, parallelogram.DA.angle)
            assert_operator(parallelogram.DA.length, :>=, 0)
            assert_in_delta(3, parallelogram.box.height)
            refute_predicate(parallelogram, :ignorable?)
          end
        end
      end

      def test_width_constraint_preserves_signed_direction
        [-60, 60, 120, 240, 300, 420].each do |angle|
          [
            [4, angle],
            LengthAngle.new(length: 4, angle:)
          ].each do |constraint|
            parallelogram = Parallelogram.new_by_width(
              vertical: [3, 90],
              wideness: constraint,
              position: [1, 2]
            )

            assert_equal(Point[1, 2], parallelogram.position)
            assert_equal(angle.to_f, parallelogram.AB.angle)
            assert_operator(parallelogram.AB.length, :>=, 0)
            assert_in_delta(4, parallelogram.box.width)
            refute_predicate(parallelogram, :ignorable?)
          end
        end
      end

      def test_parallelogram_rejects_infeasible_constraints
        [
          /height is smaller/,
          -> (constraint) { Parallelogram.new_by_height(horizontal: [2, 90], tallness: constraint) },
          [1, 45],
          /height angle must have a vertical component/,
          -> (constraint) { Parallelogram.new_by_height(horizontal: [2, 0], tallness: constraint) },
          [3, 0],
          /width is smaller/,
          -> (constraint) { Parallelogram.new_by_width(vertical: [2, 0], wideness: constraint) },
          [1, 45],
          /width angle must have a horizontal component/,
          -> (constraint) { Parallelogram.new_by_width(vertical: [2, 90], wideness: constraint) },
          [3, 90]
        ].each_slice(3) do |message, operation, constraint|
          array_error = assert_raises(Error) { operation.call(constraint) }
          carrier = LengthAngle.new(length: constraint[0], angle: constraint[1])
          carrier_error = assert_raises(Error) { operation.call(carrier) }

          assert_match(message, array_error.message)
          assert_equal(array_error.message, carrier_error.message)
        end
      end

      def test_parallelogram_constraint_forms_share_errors
        factories = [
          -> (constraint) { Parallelogram.new_by_height(horizontal: [4, 0], tallness: constraint) },
          -> (constraint) { Parallelogram.new_by_width(vertical: [3, 90], wideness: constraint) }
        ]
        malformed = [
          [-1, 90],
          [Float::INFINITY, 90],
          [3, Float::NAN],
          ["3", 90]
        ]

        malformed.each do |constraint|
          carrier_error = assert_raises(Error) do
            LengthAngle.new(length: constraint[0], angle: constraint[1])
          end

          factories.each do |factory|
            array_error = assert_raises(Error) { factory.call(constraint) }
            assert_equal(carrier_error.message, array_error.message)
          end
        end
      end
    end
  end
end
