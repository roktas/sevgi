# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Function
    module Math
      class MathTest < Minitest::Test
        def test_precision_defaults_to_constant
          assert_equal(Function::Math::PRECISION, Function::Math.precision)
        end

        def test_precision_can_be_overridden_and_restored
          Function::Math.precision = 100

          assert_equal(100, Function::Math.precision)
          Function::Math.precision = Function::Math::PRECISION

          assert_equal(Function::Math::PRECISION, Function::Math.precision)
        end

        def test_eq_respects_precision
          Function::Math.precision = 8

          assert(Function.eq?(1.999_999_999, 2.0))
          refute(Function.eq?(1.999_999_999, 2.0, precision: 9))
          refute(Function.eq?(1.999, 2.0, precision: nil))

          Function::Math.precision = Function::Math::PRECISION
        end

        def test_comparison_helpers_apply_precision
          assert(Function.ge?(1.000_000_1, 1.0))
          assert(Function.le?(0.999_999_9, 1.0))
          refute(Function.gt?(1.000_000_1, 1.0))
          refute(Function.lt?(0.999_999_9, 1.0))
          assert(Function.zero?(0.000_000_1))
        end

        def test_round_preserves_float_without_precision
          assert_equal(1.2345, Function.round(1.2345, nil))
          assert_equal(1.23, Function.round(1.2345, 2))
        end

        def test_trig_helpers_use_degrees
          [
            1.0,
            Function.sin(90),
            0.0,
            Function.cos(90),
            1.0,
            Function.tan(45),
            45.0,
            Function.atan(1),
            45.0,
            Function.atan2(1, 1),
            90.0,
            Function.asin(1),
            0.0,
            Function.acos(1)
          ].each_slice(2) { |expected, actual| assert_equal(expected, Function.approx(actual)) }
        end
      end
    end
  end
end
