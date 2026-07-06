# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class Equation
      class Linear
        class VerticalTest < Minitest::Test
          include Fixtures

          def test_fixtures_build_vertical_equation
            vequ3
          end

          def test_vertical_maps_x_and_infinite_y
            equ = Equation.vertical(1.0)

            assert_in_delta(1.0, equ.x(1))
            assert_equal(Float::INFINITY, equ.y(1))
          end

          def test_vertical_left_predicate_accepts_points_before_line
            equ = Equation.vertical(5.0)

            assert(equ.left?(Point[-5, 0]))
            assert(equ.left?([-5, 0]))
          end

          def test_vertical_on_predicate_accepts_points_on_line
            equ = Equation.vertical(5.0)

            assert(equ.on?(Point[5, 0]))
            assert(equ.on?([5, 0]))
            assert(equ.on?(Point[5, -1]))
          end

          def test_vertical_right_predicate_accepts_points_after_line
            equ = Equation.vertical(5.0)

            assert(equ.right?(Point[10, 0]))
            assert(equ.right?([10, 0]))
          end

          def test_vertical_parallel_returns_no_solution
            equ = Equation.vertical(5.0)

            assert_empty(equ.intersect(Equation.vertical(1.0)))
            assert_empty(equ.intersect(Equation.vertical(5.0)))
          end

          def test_vertical_diagonal_solution
            equ = Equation.vertical(5.0)
            line = Geometry::Line.([-2, -1], [0, 1])
            points = equ.intersect(line.equation)

            assert(Point[5, 6].eq?(*points))
          end
        end
      end
    end
  end
end
