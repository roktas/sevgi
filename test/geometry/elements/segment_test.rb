# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class SegmentTest < Minitest::Test
      include Fixtures

      def test_segment_345
        [
          53.13, segment345.direction,
          5.0,   segment345.length,
        ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }

        [
          Point[0, 0], segment345.position,
          Point[3, 4], segment345.ending,
        ].each_slice(2) { |expected, actual| assert(Point.eq?(expected, actual)) }
      end

      def test_segment_543
        [
          -53.13, segment543.direction,
          5.0,    segment543.length,
        ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }

        [
          Point[0, 4], segment543.position,
          Point[3, 0], segment543.ending,
        ].each_slice(2) { |expected, actual| assert(Point.eq?(expected, actual)) }
      end

      def test_segment_forward
        [
          Segment[1, 3].position, Segment.forward(3, 1).position,
          Segment[1, 3].ending, Segment.forward(3, 1).ending,
          Segment.forward(1, 3).position, Segment.forward(3, 1).position,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_directed
        directed = Segment.directed(length: 5, direction: direction345)

        [
          segment345.length,   directed.length,
          segment345.position, directed.position,
          segment345.ending,   directed.ending,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
