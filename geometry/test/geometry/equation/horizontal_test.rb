# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class Equation
      class Linear
        class HorizontalTest < Minitest::Test
          include Fixtures

          def test_fixtures_build_horizontal_equation
            hequ4
          end

          def test_horizontal_maps_y_to_constant
            equation = Equation.horizontal(1.0)

            assert_in_delta(1.0, equation.y(1))
            assert_raises(Error) { equation.x(1) }
          end

          def test_horizontal_rejects_invalid_constant
            ["5", Object.new, Float::INFINITY, Float::NAN].each do |value|
              assert_raises(Error) { Equation.horizontal(value) }
            end
          end

          def test_horizontal_approx_preserves_equation
            equ = Equation.horizontal(1.0004)

            assert_equal(Equation.horizontal(1.0), equ.approx(3))
          end

          def test_horizontal_parallel_returns_no_solution
            equ = Equation.horizontal(1.0)

            assert_empty(equ.intersect(Equation.horizontal(2.0)))
            assert_empty(equ.intersect(Equation.horizontal(1.0)))
          end

          def test_horizontal_intersects_linear_categories_both_ways
            horizontal = Equation.horizontal(1)
            diagonal = Equation.diagonal(slope: 1, intercept: 0)
            vertical = Equation.vertical(3)

            assert_equal([Point[1, 1]], horizontal.intersect(diagonal))
            assert_equal([Point[1, 1]], diagonal.intersect(horizontal))
            assert_equal([Point[3, 1]], horizontal.intersect(vertical))
            assert_equal([Point[3, 1]], vertical.intersect(horizontal))
          end

          def test_horizontal_shift_returns_horizontal_equation
            [
              Equation.horizontal(-3.0),
              Equation.horizontal(0.0).shift(3.0),
              Equation.horizontal(3.0),
              Equation.horizontal(0.0).shift(-3.0),
              Equation.horizontal(5.0),
              Equation.horizontal(3.0).shift(dy: 2.0)
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end

          def test_horizontal_shift_rejects_invalid_operands
            equation = Equation.horizontal(1)

            ["oops", Complex(1, 0), Float::INFINITY, Float::NAN].each do |value|
              assert_raises(Error) { equation.shift(value) }
              assert_raises(Error) { equation.shift(dx: value) }
              assert_raises(Error) { equation.shift(dy: value) }
            end
          end

          def test_horizontal_to_s_preserves_sign
            assert_equal("Linear<y = -3.0>", Equation.horizontal(-3.0).to_s)
          end
        end
      end
    end
  end
end
