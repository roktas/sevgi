# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class EquationTest < Minitest::Test
      def test_equation_rect_intersection
        rect = Rect[2, 7]

        [
          [ [ 2.0, 7.0 ], [ 0.0, 1.0 ] ],      rect.intersection(Line.([ 0.0, 1.0 ], [ 1.0, 4.0 ]).equation).map(&:deconstruct),
          [ [ 1.0, 0.0 ], [ 1.0, 7.0 ] ],      rect.intersection(Line.([ 1.0, 1.0 ], [ 1.0, 4.0 ]).equation).map(&:deconstruct),
          [ [ 2.0, 1.0 ], [ 0.0, 1.0 ] ],      rect.intersection(Line.([ 1.0, 1.0 ], [ 5.0, 1.0 ]).equation).map(&:deconstruct),
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_equation_rect_intersection_single
        rect = Rect[2, 4]
        equ  = Equation.diagonal(slope: 1.0, intercept: 4.0)

        [
          [ [ 0.0, 4.0 ] ],      rect.intersection(equ).map(&:deconstruct),
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
