# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class RectTest < Minitest::Test
      include Fixtures

      def test_rect_construction_usual
        rect = Rect[3, 4, position: [ 1, 2 ]]

        [
          1.0,            rect.position.x,
          2.0,            rect.position.y,

          rect345.width,  rect.width,
          rect345.height, rect.height
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_rect_construction_brackets
        assert_equal(rect345, Rect[3, 4])
      end

      def test_rect_construction_points
        rect = Rect.(
          rect345.top_left.translate(2.0, 3.0),
          rect345.bottom_right.translate(2.0, 3.0)
        )

        [
          2.0,            rect.position.x,
          3.0,            rect.position.y,

          rect345.width,  rect.width,
          rect345.height, rect.height
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_rect_inside?
        assert(line345.box.inside?(Point[1, 1]))
      end

      def test_rect_on?
        assert(line345.box.on?(Point[3, 0]))
      end

      def test_rect_outside?
        assert(line345.box.outside?(Point[5, 0]))
      end
    end
  end
end
