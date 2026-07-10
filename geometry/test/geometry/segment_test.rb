# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class SegmentTest < Minitest::Test
      def test_segment_exposes_length_angle_and_endpoint
        segment = Segment[4, 30]
        [
          4.0,
          segment.length,
          30.0,
          segment.angle,
          Point[1 + (4 * F.cos(30)), 4.0],
          segment.ending([1.0, 2.0])
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_rejects_invalid_direct_components
        [
          ["x", 0],
          [Object.new, 0],
          [Complex(1, 2), 0],
          [Float::INFINITY, 0],
          [Float::NAN, 0],
          [Class.new(Numeric) { def to_f = raise "conversion failed" }.new, 0]
        ].each do |length, angle|
          error = assert_raises(Error) { Segment[length, angle] }
          assert_match(/length/, error.message)
        end
      end

      def test_segment_accepts_finite_real_numeric_coercions
        segment = Segment[Rational(1, 2), Rational(61, 2)]

        [
          0.5,
          segment.length,
          30.5,
          segment.angle,
          true,
          Segment.eq?([Rational(1, 2), Rational(61, 2)], segment)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_rejects_malformed_tuples
        segment = Segment[1, 0]

        [[], [1], [1, 2, 3], ["x", 2], [Object.new, 2]].each do |tuple|
          assert_raises(Error) { segment.eq?(tuple) }
        end
      end

      def test_segment_ending_uses_start_point
        segment = Segment[3, 180]
        [
          Point[0.0, 4.0],
          segment.ending([3.0, 4.0])
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_exposes_components_and_reverse_angle
        segment = Segment[5, F.atan2(4, 3)]

        [
          3.0,
          F.approx(segment.x),
          4.0,
          F.approx(segment.y),
          segment.angle + 180.0,
          segment.reverse.angle
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_direction_helpers_return_cardinal_segments
        [
          Segment[2, 0],
          Segment.rightward(2),
          Segment[2, 90],
          Segment.downward(2),
          Segment[2, 180],
          Segment.leftward(2),
          Segment[2, -90],
          Segment.upward(2)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_line_preserves_position
        line = Segment[5, 45].line([2, 3])

        [
          5.0,
          line.length,
          45.0,
          line.angle,
          Point[2, 3],
          line.position
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_eq_respects_precision
        left = Segment[1.0004, 45.0004]
        right = Segment[1.00049, 45.00049]

        assert(left.eq?(right, precision: 3))
        refute(left.eq?(right, precision: 4))
      end
    end
  end
end
