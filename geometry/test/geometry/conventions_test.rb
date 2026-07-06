# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class ConventionsTest < Minitest::Test
      def test_screen_axes_point_right_and_down
        [
          Point[1, 0],
          Segment[1, 0].ending(Origin).approx,
          Point[0, 1],
          Segment[1, 90].ending(Origin).approx,
          Point[0, -1],
          Segment[1, -90].ending(Origin).approx,
          Point[-1, 0],
          Segment[1, 180].ending(Origin).approx
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_positive_angles_turn_clockwise
        [
          45.0,
          Point.angle([0, 0], [1, 1]),
          -45.0,
          Point.angle([0, 0], [1, -1]),
          Point[0, 1],
          Point[1, 0].rotate(90).approx,
          Point[-1, 0],
          Point[0, 1].rotate(90).approx
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_point_relations_use_screen_edges
        point = Point[1, 1]

        assert(point.above?([1, 2]))
        assert(point.below?([1, 0]))
        assert(point.left?([2, 1]))
        assert(point.right?([0, 1]))
      end

      def test_point_inputs_accept_arrays
        [
          Line.(Point[0, 0], Point[3, 4]),
          Line.([0, 0], [3, 4]),
          Rect.(Point[0, 0], Point[3, 4]),
          Rect.([0, 0], [3, 4])
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_segment_inputs_accept_arrays
        [
          Polyline[Segment[2, 0], Segment[1, 90]],
          Polyline[[2, 0], [1, 90]],
          Parm[Segment[3, 0], Segment[4, -90]],
          Parm[[3, 0], [4, -90]]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_constructor_dialects_separate_shapes
        [
          Line.(Origin, [3, 4]),
          Line[5, F.atan2(4, 3)],
          Rect.(Origin, [3, 4]),
          Rect[3, 4],
          Polyline.(Origin, [2, 0], [2, 1]),
          Polyline[Segment.horizontal(2), Segment.vertical(1)]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_boxes_use_top_left_positions
        rect = Rect[3, 4, position: [10, 20]]

        [
          Point[10, 20],
          rect.top_left,
          Point[13, 20],
          rect.top_right,
          Point[13, 24],
          rect.bottom_right,
          Point[10, 24],
          rect.bottom_left
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
