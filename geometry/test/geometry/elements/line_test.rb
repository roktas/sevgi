# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class LineTest < Minitest::Test
      include Fixtures

      def test_line_345_exposes_angle_length_and_endpoints
        [
          53.13,
          line345.angle,
          5.0,
          line345.length
        ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }

        [
          Point[0, 0],
          line345.position,
          Point[3, 4],
          line345.ending
        ].each_slice(2) { |expected, actual| assert(Point.eq?(expected, actual)) }
      end

      def test_line_543_exposes_negative_angle_and_endpoints
        [
          -53.13,
          line543.angle,
          5.0,
          line543.length
        ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }

        [
          Point[0, 4],
          line543.position,
          Point[3, 0],
          line543.ending
        ].each_slice(2) { |expected, actual| assert(Point.eq?(expected, actual)) }
      end

      def test_line_from_points_preserves_endpoints
        [
          Line.from_points(Origin, [1, 3]).position,
          Origin,
          Line.from_points(Origin, [1, 3]).ending,
          Point[1, 3]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_line_exposes_endpoint_shortcuts
        line = Line[3, 0]

        [
          Point[0, 0],
          line.A(),
          Point[3, 0],
          line.B(),
          3.0,
          line.AB.length
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

        refute_respond_to(line, :AA)
      end

      def test_line_from_segment_matches_fixture_line
        line = Line.from_length_angle(5, angle345)

        [
          line345.length,
          line.length,
          line345.position,
          line.position,
          line345.ending,
          line.ending
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_line_over_accepts_points_on_segment
        assert(line345.over?(Point[1.5, 2.0]))
        assert(line345.over?([1.5, 2.0]))
        assert(line345.over?(line345.starting))
        assert(line345.over?(line345.ending))
      end

      def test_line_over_rejects_points_outside_segment
        refute(line345.over?(Point[6.0, 8.0]))
        refute(line345.over?(Point[1.0, 3.0]))
      end

      def test_line_shift_matches_equation_offset
        [
          Line[5, 0],
          Line[5, 30],
          Line[5, 45],
          Line[5, 90],
          Line[5, -45]
        ].each do |line|
          assert_equal(line.equation.shift(3).approx, line.shift(3).equation.approx)
        end
      end

      def test_line_shift_uses_signed_offset
        [
          Point[0, -3],
          Line[5, 0].shift(3).starting.approx,
          Point[5, -3],
          Line[5, 0].shift(3).ending.approx,
          Point[3, 0],
          Line[5, 90].shift(3).starting.approx,
          Point[3, 5],
          Line[5, 90].shift(3).ending.approx
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_line_shift_rejects_invalid_distance
        ["oops", Complex(1, 0), Float::INFINITY, Float::NAN].each do |value|
          assert_raises(Error) { line345.shift(value) }
        end
      end

      def test_line_ignorable_detects_zero_box
        assert(Line[0, 0].ignorable?)
        refute(line345.ignorable?)
      end
    end
  end
end
