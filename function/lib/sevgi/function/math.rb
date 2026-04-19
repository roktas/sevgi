# frozen_string_literal: true

# rubocop:disable Layout/LineLength

module Sevgi
  module Function
    module Math
      @precision = PRECISION = 6

      class << self
        attr_accessor :precision
      end

      def acos(value)                      = to_degrees(::Math.acos(value))

      def acot(value)                      = 90.0 - to_degrees(::Math.atan(value))

      def approx(float, precision = nil)   = float.round(precision || Function::Math.precision)

      def asin(value)                      = to_degrees(::Math.asin(value))

      def atan(value)                      = to_degrees(::Math.atan(value))

      def atan2(y, x)                      = to_degrees(::Math.atan2(y, x))

      def cos(degrees)                     = ::Math.cos(to_radians(degrees))

      def cot(degrees)                     = 1.0 / ::Math.tan(to_radians(degrees))

      def count(length, division)          = (length / division.to_f).to_i

      def eq?(left, right, precision: nil) = approx(left, precision) == approx(right, precision)

      def ge?(left, right, precision: nil) = approx(left, precision) >= approx(right, precision)

      def gt?(left, right, precision: nil) = approx(left, precision) > approx(right, precision)

      def le?(left, right, precision: nil) = approx(left, precision) <= approx(right, precision)

      def lt?(left, right, precision: nil) = approx(left, precision) < approx(right, precision)

      def round(float, precision)          = precision ? float.round(precision) : float

      def sin(degrees)                     = ::Math.sin(to_radians(degrees))

      def tan(degrees)                     = ::Math.tan(to_radians(degrees))

      def to_degrees(radians)              = radians.to_f * 180 / ::Math::PI

      def to_radians(degrees)              = degrees.to_f / 180 * ::Math::PI

      def zero?(value, precision: nil)     = eq?(value, 0.0, precision:)
    end

    extend Math
  end
end
