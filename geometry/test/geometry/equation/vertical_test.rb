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

          def test_vertical_maps_x_and_rejects_y_lookup
            equ = Equation.vertical(1.0)

            assert_in_delta(1.0, equ.x(1))
            assert_raises(Error) { equ.y(1) }
          end

          def test_vertical_rejects_invalid_constant
            ["5", Object.new, Float::INFINITY, Float::NAN].each do |value|
              assert_raises(Error) { Equation.vertical(value) }
            end
          end

          def test_vertical_approx_preserves_equation
            equ = Equation.vertical(5.0004)

            assert_equal(Equation.vertical(5.0), equ.approx(3))
          end

          def test_vertical_equality_compares_constant
            assert_equal(Equation.vertical(5.0), Equation.vertical(5.0))
            refute_equal(Equation.vertical(5.0), Equation.vertical(6.0))
          end

          def test_vertical_on_predicate_accepts_points_on_line
            equ = Equation.vertical(5.0)

            assert(equ.on?(Point[5, 0]))
            assert(equ.on?([5, 0]))
            assert(equ.on?(Point[5, -1]))
          end

          def test_vertical_parallel_returns_no_solution
            equ = Equation.vertical(5.0)

            assert_empty(equ.intersect(Equation.vertical(1.0)))
            assert_empty(equ.intersect(Equation.vertical(5.0)))
          end

          def test_vertical_shift_returns_vertical_equation
            [
              Equation.vertical(3.0),
              Equation.vertical(0.0).shift(3.0),
              Equation.vertical(-3.0),
              Equation.vertical(0.0).shift(-3.0),
              Equation.vertical(5.0),
              Equation.vertical(3.0).shift(dx: 2.0)
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end

          def test_vertical_mapping_and_shift_reject_invalid_operands
            equation = Equation.vertical(1)

            ["oops", Complex(1, 0), Float::INFINITY, Float::NAN].each do |value|
              assert_raises(Error) { equation.x(value) }
              assert_raises(Error) { equation.shift(value) }
              assert_raises(Error) { equation.shift(dx: value) }
              assert_raises(Error) { equation.shift(dy: value) }
            end
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
