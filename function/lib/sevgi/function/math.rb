# frozen_string_literal: true

module Sevgi
  module Function
    module Math
      PRECISION = 6
      PRECISION_KEY = :sevgi_function_math_precision

      private_constant :PRECISION_KEY

      def self.precision
        precision = Thread.current.thread_variable_get(PRECISION_KEY)

        precision.nil? ? PRECISION : precision
      end

      def self.precision=(precision)
        Thread.current.thread_variable_set(PRECISION_KEY, precision)
      end

      def acos(value) = to_degrees(::Math.acos(value))

      def acot(value) = 90.0 - to_degrees(::Math.atan(value))

      def approx(float, precision = nil)
        float.round(precision.nil? ? Function::Math.precision : precision)
      end

      def asin(value) = to_degrees(::Math.asin(value))

      def atan(value) = to_degrees(::Math.atan(value))

      def atan2(y, x) = to_degrees(::Math.atan2(y, x))

      def cos(degrees) = ::Math.cos(to_radians(degrees))

      def cot(degrees) = 1.0 / ::Math.tan(to_radians(degrees))

      def count(length, division) = (length / division.to_f).to_i

      def eq?(left, right, precision: nil) = approx(left, precision) == approx(right, precision)

      def ge?(left, right, precision: nil) = approx(left, precision) >= approx(right, precision)

      def gt?(left, right, precision: nil) = approx(left, precision) > approx(right, precision)

      def le?(left, right, precision: nil) = approx(left, precision) <= approx(right, precision)

      def lt?(left, right, precision: nil) = approx(left, precision) < approx(right, precision)

      def round(float, precision) = precision ? float.round(precision) : float

      def sin(degrees) = ::Math.sin(to_radians(degrees))

      def tan(degrees) = ::Math.tan(to_radians(degrees))

      def to_degrees(radians) = radians.to_f * 180 / ::Math::PI

      def to_radians(degrees) = degrees.to_f / 180 * ::Math::PI

      def with_precision(precision, &block)
        ArgumentError.("Block required") unless block

        previous = Thread.current.thread_variable_get(PRECISION_KEY)
        Function::Math.precision = precision
        block.call
      ensure
        Function::Math.precision = previous if block
      end

      def zero?(value, precision: nil) = eq?(value, 0.0, precision:)
    end

    extend Math
  end
end
