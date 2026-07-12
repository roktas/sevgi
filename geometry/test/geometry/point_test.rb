# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class PointTest < Minitest::Test
      def test_point_brackets_coerce_coordinates
        point = Point[3, 5]
        [
          3.0,
          point.x,
          5.0,
          point.y
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_origin_is_zero
        [
          0.0,
          Origin.x,
          0.0,
          Origin.y
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_equals_float_coordinates
        assert_equal(Point[3, 5], Point[3.0, 5.0])
      end

      def test_point_rejects_invalid_direct_coordinates
        [
          ["x", 0],
          [Object.new, 0],
          [Complex(1, 0), 0],
          [Complex(1, 2), 0],
          [Float::INFINITY, 0],
          [Float::NAN, 0],
          [Class.new(Numeric) { def to_f = raise "conversion failed" }.new, 0]
        ].each do |x, y|
          error = assert_raises(Error) { Point[x, y] }
          assert_match(/x/, error.message)
        end
      end

      def test_point_accepts_finite_real_numeric_coercions
        point = Point[Rational(1, 2), Rational(5, 2)]

        [
          0.5,
          point.x,
          2.5,
          point.y,
          true,
          Point.eq?([Rational(1, 2), Rational(5, 2)], point)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_rejects_malformed_tuples
        point = Point[0, 0]

        [[], [1], [1, 2, 3], ["x", 2], [Object.new, 2]].each do |tuple|
          assert_raises(Error) { point.eq?(tuple) }
        end
      end

      def test_point_angle_returns_degrees_between_points
        [
          45.0,
          Point.angle(Point[0, 0], Point[1, 1]),
          -135.0,
          Point.angle(Point[1, 1], Point[0, 0])
        ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
      end

      def test_point_affinity_transforms_coordinates
        point = Point[3, 4]

        [
          Point[4, 6],
          point.translate(1, 2),
          Point[4, 5],
          point.translate(1),
          Point[3, -4],
          point.reflect(y: false),
          Point[-3, 4],
          point.reflect(x: false),
          Point[-3, -4],
          point.reflect,
          Point[-4, 3],
          point.rotate(90).approx,
          Point[6, 8],
          point.scale(2),
          Point[6, 12],
          point.scale(2, 3)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_skew_transforms_coordinates
        point = Point[3, 4]

        [
          Point[7, 4],
          point.skew_x(45).approx,
          Point[3, 7],
          point.skew_y(45).approx,
          Point[7, 7],
          point.skew(45).approx,
          Point[7, 4],
          point.skew(45, 0).approx
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_affinity_rejects_invalid_operands
        point = Point[3, 4]
        invalid = ["oops", Complex(1, 0), Float::INFINITY, Float::NAN]
        operations = [
          -> (value) { point.rotate(value) },
          -> (value) { point.scale(value) },
          -> (value) { point.scale(1, value) },
          -> (value) { point.skew(value) },
          -> (value) { point.skew(1, value) },
          -> (value) { point.skew_x(value) },
          -> (value) { point.skew_y(value) },
          -> (value) { point.translate(value) },
          -> (value) { point.translate(1, value) }
        ]

        invalid.product(operations).each do |value, operation|
          assert_raises(Error) { operation.call(value) }
        end

        [nil, 0, "true"].each do |value|
          assert_raises(Error) { point.reflect(x: value) }
          assert_raises(Error) { point.reflect(y: value) }
        end
      end

      def test_point_sort_orders_by_x_then_y
        [
          [Point[9, 5], Point[6, 7]].sort,
          [Point[6, 7], Point[9, 5]]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_sort_orders_by_x_when_y_matches
        [
          [Point[1, 5], Point[3, 5]].sort,
          [Point[1, 5], Point[3, 5]],
          [Point[3, 5], Point[1, 5]].sort,
          [Point[1, 5], Point[3, 5]]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_sort_orders_by_y_when_x_matches
        [
          [Point[1, 3], Point[1, 5]].sort,
          [Point[1, 3], Point[1, 5]],
          [Point[1, 5], Point[1, 3]].sort,
          [Point[1, 3], Point[1, 5]]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_sort_keeps_equal_points
        [
          [Point[1, 3], Point[1, 3]].sort,
          [Point[1, 3], Point[1, 3]]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_extremes_support_between_checks
        interval = [Point[0, 5], Point[0, 3]]
        [
          interval.min,
          Point[0, 3],
          interval.max,
          Point[0, 5],
          Point[0, 4].between?(interval.min, interval.max),
          true,
          Point[0, 5].between?(interval.min, interval.max),
          true,
          Point[0, 6].between?(interval.min, interval.max),
          false
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
