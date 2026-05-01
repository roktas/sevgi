# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class Equation
      class Linear
        class VerticalTest < Minitest::Test
          include Fixtures

          def test_fixtures_construction
            vequ3
          end

          def test_vertical
            equ = Equation.vertical(1.0)

            assert_in_delta(1.0, equ.x(1))
            assert_equal(Float::INFINITY, equ.y(1))
          end

          def test_vertical_left
            equ = Equation.vertical(5.0)

            assert(equ.left?(Point[-5, 0]))
          end

          def test_vertical_on?
            equ = Equation.vertical(5.0)

            assert(equ.on?(Point[5, 0]))
            assert(equ.on?(Point[5, -1]))
          end

          def test_vertical_right
            equ = Equation.vertical(5.0)

            assert(equ.right?(Point[10, 0]))
          end

          def test_vertical_vertical_solution
            equ    = Equation.vertical(5.0)
            points = equ.intersect(Equation.vertical(1.0))

            assert_equal(Point[Float::INFINITY, Float::INFINITY], *points)
          end

          def test_vertical_diagonal_solution
            equ    = Equation.vertical(5.0)
            line   = Geometry::Line.([ -2, -1 ], [ 0, 1 ])
            points = equ.intersect(line.equation)

            assert(Point[5, 6].eq?(*points))
          end
        end
      end
    end
  end
end
