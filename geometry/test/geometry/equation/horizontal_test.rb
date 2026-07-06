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

          def test_horizontal_parallel_returns_no_solution
            equ = Equation.horizontal(1.0)

            assert_empty(equ.intersect(Equation.horizontal(2.0)))
            assert_empty(equ.intersect(Equation.horizontal(1.0)))
          end
        end
      end
    end
  end
end
