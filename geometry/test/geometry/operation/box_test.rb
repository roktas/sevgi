# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class OperationBoxTest < Minitest::Test
      def test_box_returns_single_element_box
        line = Line.([2, 3], [8, 7])

        assert_equal(line.box, Operation.box(line))
      end

      def test_box_encloses_mixed_elements
        rect = Rect[10, 5, position: [2, 3]]
        line = Line.([-4, 8], [20, 12])

        assert_equal(Rect.from_corners([-4, 3], [20, 12]), Operation.box(rect, line))
      end

      def test_box_supports_negative_coordinates
        a = Rect[2, 3, position: [-8, -5]]
        b = Rect[4, 2, position: [-3, -9]]

        assert_equal(Rect.from_corners([-8, -9], [1, -2]), Operation.box(a, b))
      end

      def test_box_includes_zero_size_elements
        point_like = Line.([20, -4], [20, -4])
        rect = Rect[4, 3, position: [2, 5]]

        assert_equal(Rect.from_corners([2, -4], [20, 8]), Operation.box(rect, point_like))
      end

      def test_box_handles_only_zero_size_elements
        a = Line.([3, 4], [3, 4])
        b = Line.([-2, 9], [-2, 9])

        assert_equal(Rect.from_corners([-2, 4], [3, 9]), Operation.box(a, b))
      end

      def test_box_rejects_non_geometry_argument
        [nil, false, Object.new].each do |invalid|
          [[invalid, Rect[1, 1]], [Rect[1, 1], invalid], [nil, invalid]].each do |elements|
            error = assert_raises(Operation::OperationInapplicableError) { Operation.box(*elements) }

            assert_match(/Not a Geometric Element/, error.message)
          end
        end
      end

      def test_box_requires_an_element
        error = assert_raises(Sevgi::ArgumentError) { Operation.box }

        assert_match(/At least one geometric element/, error.message)
      end

      def test_box_does_not_mutate_inputs
        a = Rect[2, 3, position: [1, 2]]
        b = Line.([8, 9], [12, 7])
        before = [a, b].map { it.points.map(&:deconstruct) }

        Operation.box(a, b)

        assert_equal(before, [a, b].map { it.points.map(&:deconstruct) })
      end
    end
  end
end
