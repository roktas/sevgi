# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class Equation
      class Linear
        class DiagonalTest < Minitest::Test
          include Fixtures

          def test_fixtures_construction
            [
              0.0, line345.equation.y(0),
              4.0, line543.equation.y(0)
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_diagonal_line_construction_basics
            equ = Equation.diagonal(slope: 2.0, intercept: -10.0)

            [
              -10.0, equ.y(0),
                5.0, equ.x(0),
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_diagonal_line_construction_from_lines
            [
               10.0, Geometry::Line[1.0,  F.atan(2)].equation.y(5),
              -10.0, Geometry::Line[1.0, -F.atan(2)].equation.y(5)
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_different_construction_methods_give_same_results
            equ1 = Geometry::Line[1.0, F.atan(2), position: [ 5.0, 0.0 ]].equation
            equ2 = Equation.diagonal(slope: 2.0, intercept: -10.0)

            assert_equal(equ1.approx, equ2.approx)
          end

          def test_line_shifting_basics
            equ = line345.equation.shift(3.0 * F.sin(line345.angle))

            assert_in_delta(4.0 / 3.0, equ.slope)
            assert_in_delta(-4.0,      equ.intercept)
          end

          def test_line_shifting_with_lines_constructed_from_lines
            angle = F.atan(2)

            equ1 = Geometry::Line[1.0, angle].equation
            equ2 = Geometry::Line[1.0, angle, position: [ 5.0, 0.0 ]].equation

            shifted = equ1.shift(10.0 * F.sin(90.0 - angle))

            assert_equal(shifted.approx, equ2.approx)
          end

          def test_diagonal_diagonal_solution
            equ    = Equation.diagonal(slope: 4.0 / 3.0, intercept: -4)
            line   = Geometry::Line.([ -2, -1 ], [ 0, 1 ])
            points = equ.intersect(line.equation)

            # assert_equal(Point[15, 16], *points)
            assert(Point[15, 16].eq?(*points))
          end

          def test_point_left?
            assert(line345.left?(Point[-5, 0]))
          end

          def test_point_on?
            assert(line345.on?(Point[0, 0]))
          end

          def test_point_right?
            assert(line345.right?(Point[5, 0]))
          end
        end
      end
    end
  end
end
