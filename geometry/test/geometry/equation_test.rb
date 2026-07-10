# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class EquationTest < Minitest::Test
      def test_rect_intersection_returns_boundary_points
        rect = Rect[2, 7]

        [
          [[2.0, 7.0], [0.0, 1.0]],
          rect.intersection(Line.([0.0, 1.0], [1.0, 4.0]).equation).map(&:deconstruct),
          [[1.0, 0.0], [1.0, 7.0]],
          rect.intersection(Line.([1.0, 1.0], [1.0, 4.0]).equation).map(&:deconstruct),
          [[2.0, 1.0], [0.0, 1.0]],
          rect.intersection(Line.([1.0, 1.0], [5.0, 1.0]).equation).map(&:deconstruct)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_equation_rect_intersection_returns_single_point
        rect = Rect[2, 4]
        equ = Equation.diagonal(slope: 1.0, intercept: 4.0)

        [
          [[0.0, 4.0]],
          rect.intersection(equ).map(&:deconstruct)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_intersection_precision_rounds_after_membership
        triangle = Triangle[Segment[2, 0], Segment[1, 150]]
        equ = Equation.vertical(1.2)

        [
          [[1.2, 0.0], [1.2, 0.5]],
          triangle.intersection(equ, precision: 1).map(&:deconstruct),
          [[1.2, 0.0], [1.2, 0.4619]],
          triangle.intersection(equ, precision: 4).map(&:deconstruct)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_intersection_precision_ignores_thread_default
        triangle = Triangle[Segment[2, 0], Segment[1, 150]]
        equ = Equation.vertical(1.2)

        F.with_precision(2) do
          assert_equal(
            [[1.2, 0.0], [1.2, 0.5]],
            triangle.intersection(equ, precision: 1).map(&:deconstruct)
          )
        end
      end

      def test_intersect_rejects_non_equation
        error = assert_raises(Error) { Equation.horizontal(1).intersect(Object.new) }

        assert_match(/Must be an equation/, error.message)
      end

      def test_unimplemented_intersection_raises_panic_error
        assert_raises(PanicError) do
          Equation.horizontal(3).send(:linear_vs_quadratic, Object.new)
        end
      end

      def test_unknown_equation_intersection_raises_panic_error
        custom = Class.new(Equation).new
        error = assert_raises(PanicError) { Equation.horizontal(1).intersect(custom) }

        assert_match(/Intersection not implemented/, error.message)
      end
    end
  end
end
