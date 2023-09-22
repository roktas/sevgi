# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Function
    module Float
      class FloatTest < Minitest::Test
        def test_precision_default
          assert_equal(Function::Float::PRECISION, Function::Float.precision)
        end

        def test_precision_attribute
          Function::Float.precision = 100

          assert_equal(100, Function::Float.precision)
          Function::Float.precision = Function::Float::PRECISION

          assert_equal(Function::Float::PRECISION, Function::Float.precision)
        end

        def test_almost_equal
          Function::Float.precision = 8

          assert(Function.eq?(1.999_999_999, 2.0))
          refute(Function.eq?(1.999_999_999, 2.0, precision: 9))
          refute(Function.eq?(1.999, 2.0, precision: nil))

          Function::Float.precision = Function::Float::PRECISION
        end
      end
    end
  end
end
