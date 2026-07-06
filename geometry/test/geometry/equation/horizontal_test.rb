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
            assert_in_delta(1.0, Equation.horizontal(1.0).y(1))
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

          def test_horizontal_to_s_preserves_sign
            assert_equal("Linear<y = -3.0>", Equation.horizontal(-3.0).to_s)
          end
        end
      end
    end
  end
end
