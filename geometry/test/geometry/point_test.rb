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

      def test_point_angle_returns_degrees_between_points
        [
          45.0,
          Point.angle(Point[0, 0], Point[1, 1]),
          -135.0,
          Point.angle(Point[1, 1], Point[0, 0])
        ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
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
