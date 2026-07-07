# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class RectTest < Minitest::Test
      include Fixtures

      def test_rect_construction_preserves_position_and_size
        rect = Rect.from_size(3, 4, position: [1, 2])

        [
          1.0,
          rect.position.x,
          2.0,
          rect.position.y,

          rect345.width,
          rect.width,
          rect345.height,
          rect.height
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_rect_exposes_corners_and_sides
        rect = Rect[3, 4, position: [1, 2]]

        [
          Point[1, 2],
          rect.top_left,
          Point[4, 2],
          rect.top_right,
          Point[4, 6],
          rect.bottom_right,
          Point[1, 6],
          rect.bottom_left,
          3.0,
          rect.top.length,
          4.0,
          rect.right.length,
          3.0,
          rect.bottom.length,
          4.0,
          rect.left.length
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_rect_from_size_builds_origin_rect
        assert_equal(rect345, Rect.from_size(3, 4))
      end

      def test_rect_from_corners_preserves_position_and_size
        rect = Rect.from_corners(
          rect345.top_left.translate(2.0, 3.0),
          rect345.bottom_right.translate(2.0, 3.0)
        )

        [
          2.0,
          rect.position.x,
          3.0,
          rect.position.y,

          rect345.width,
          rect.width,
          rect345.height,
          rect.height
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_rect_at_moves_to_absolute_position
        rect = Rect[3, 4, position: [1, 2]]

        [
          Rect[3, 4, position: [10, 20]],
          rect.at([10, 20]),
          Rect[3, 4, position: [11, 18]],
          rect.at([10, 20], dx: 1, dy: -2),
          Rect[3, 4, position: [2, 2]],
          rect.at(dx: 1)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_rect_draw_emits_rect_attributes
        attrs = nil
        node = Object.new
        node.define_singleton_method(:rect) { |**kwargs| attrs = kwargs }

        Rect[3, 4, position: [1, 2]].draw(node, id: "box")

        assert_equal({x: 1.0, y: 2.0, width: 3.0, height: 4.0, id: "box"}, attrs)
      end

      def test_square_builds_equal_sides
        square = Square[5, position: [1, 2]]

        [
          5.0,
          square.width,
          5.0,
          square.height,
          5.0,
          square.length,
          Point[1, 2],
          square.position
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_rect_inside_predicate_accepts_inner_point
        assert(line345.box.inside?(Point[1, 1]))
        assert(line345.box.inside?([1, 1]))
      end

      def test_rect_on_predicate_accepts_boundary_point
        assert(line345.box.on?(Point[3, 0]))
        assert(line345.box.on?([3, 0]))
      end

      def test_rect_outside_predicate_accepts_outer_point
        assert(line345.box.outside?(Point[5, 0]))
        assert(line345.box.outside?([5, 0]))
      end
    end
  end
end
