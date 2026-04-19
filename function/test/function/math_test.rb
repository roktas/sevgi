# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Function
    module Math
      class MathTest < Minitest::Test
        def test_precision_default
          assert_equal(Function::Math::PRECISION, Function::Math.precision)
        end

        def test_precision_attribute
          Function::Math.precision = 100

          assert_equal(100, Function::Math.precision)
          Function::Math.precision = Function::Math::PRECISION

          assert_equal(Function::Math::PRECISION, Function::Math.precision)
        end

        def test_almost_equal
          Function::Math.precision = 8

          assert(Function.eq?(1.999_999_999, 2.0))
          refute(Function.eq?(1.999_999_999, 2.0, precision: 9))
          refute(Function.eq?(1.999, 2.0, precision: nil))

          Function::Math.precision = Function::Math::PRECISION
        end
      end
    end
  end
end
