# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class SegmentTest < Minitest::Test
      def test_segment_construction
        segment = Segment[4, 30]
        [
          4.0,                             segment.length,
          30.0,                            segment.angle,
          Point[1 + 4 * F.cos(30), 4.0], segment.ending([ 1.0, 2.0 ]),
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_ending
        segment = Segment[3, 180]
        [
          Point[0.0, 4.0], segment.ending([ 3.0, 4.0 ]),
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
