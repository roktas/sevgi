# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class Equation
      class Linear
        class DiagonalTest < Minitest::Test
          include Fixtures

          def test_fixtures_build_diagonal_equations
            [
              0.0,
              line345.equation.y(0),
              4.0,
              line543.equation.y(0)
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_diagonal_equation_maps_x_and_y
            equ = Equation.diagonal(slope: 2.0, intercept: -10.0)

            [
              -10.0,
              equ.y(0),
              5.0,
              equ.x(0)
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_diagonal_mappings_and_shift_reject_invalid_operands
            equation = Equation.diagonal(slope: 2, intercept: 1)
            invalid = ["oops", Complex(1, 0), Float::INFINITY, Float::NAN]

            invalid.each do |value|
              assert_raises(Error) { equation.x(value) }
              assert_raises(Error) { equation.y(value) }
              assert_raises(Error) { equation.shift(value) }
              assert_raises(Error) { equation.shift(dx: value) }
              assert_raises(Error) { equation.shift(dy: value) }
            end
          end

          def test_diagonal_rejects_invalid_coefficients
            ["2", Object.new, Float::INFINITY, Float::NAN].each do |value|
              assert_raises(Error) { Equation.diagonal(slope: value, intercept: 0) }
              assert_raises(Error) { Equation.diagonal(slope: 1, intercept: value) }
            end
          end

          def test_diagonal_rejects_zero_slope
            assert_raises(Error) { Equation.diagonal(slope: 0, intercept: 1) }
            assert_raises(Error) { Diagonal.new(slope: -0.0, intercept: 1) }
          end

          def test_diagonal_equation_from_line_maps_y
            [
              10.0,
              Geometry::Line[1.0, F.atan(2)].equation.y(5),
              -10.0,
              Geometry::Line[1.0, -F.atan(2)].equation.y(5)
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_diagonal_equation_matches_shifted_line
            equ1 = Geometry::Line[1.0, F.atan(2), position: [5.0, 0.0]].equation
            equ2 = Equation.diagonal(slope: 2.0, intercept: -10.0)

            assert_equal(equ1.approx, equ2.approx)
          end

          def test_shift_offsets_diagonal_equation
            equ = line345.equation.shift(3.0 * F.sin(line345.angle))

            assert_in_delta(4.0 / 3.0, equ.slope)
            assert_in_delta(-4.0, equ.intercept)
          end

          def test_shift_matches_offset_line
            angle = F.atan(2)

            equ1 = Geometry::Line[1.0, angle].equation
            equ2 = Geometry::Line[1.0, angle, position: [5.0, 0.0]].equation

            shifted = equ1.shift(10.0 * F.sin(90.0 - angle))

            assert_equal(shifted.approx, equ2.approx)
          end

          def test_diagonal_diagonal_solution
            equ = Equation.diagonal(slope: 4.0 / 3.0, intercept: -4)
            line = Geometry::Line.([-2, -1], [0, 1])
            points = equ.intersect(line.equation)

            assert(Point[15, 16].eq?(*points))
          end

          def test_diagonal_parallel_returns_no_solution
            equ = Equation.diagonal(slope: 2.0, intercept: 1.0)

            assert_empty(equ.intersect(Equation.diagonal(slope: 2.0, intercept: 3.0)))
            assert_empty(equ.intersect(Equation.diagonal(slope: 2.0, intercept: 1.0)))
          end

          def test_diagonal_on_predicate_accepts_origin
            assert(line345.on?(Point[0, 0]))
            assert(line345.on?([0, 0]))
          end
        end
      end
    end
  end
end
