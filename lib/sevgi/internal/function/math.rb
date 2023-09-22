# frozen_string_literal: true

module Sevgi
  module Function
    module Math
      def acos(value)                           = to_degrees(::Math.acos(value))

      def acot(value)                           = 90.0 - to_degrees(::Math.atan(value))

      def asin(value)                           = to_degrees(::Math.asin(value))

      def atan(value)                           = to_degrees(::Math.atan(value))

      def complement(degrees)                   = 90.0 - degrees

      def cos(degrees)                          = ::Math.cos(to_radians(degrees))

      def cot(degrees)                          = 1.0 / ::Math.tan(to_radians(degrees))

      def golden                                = @golden ||= ((1.0 + ::Math.sqrt(5)) / 2.0)

      def horizontal?(degrees, precision = nil) = zero?(degrees % 180.0, precision:)

      def nangle(degrees)                       = degrees - 90.0

      def sin(degrees)                          = ::Math.sin(to_radians(degrees))

      def sqrt2                                 = @sqrt2  ||= ::Math.sqrt(2)

      def sqrt2h                                = @sqrt2h ||= (sqrt2 / 2.0)

      def tan(degrees)                          = ::Math.tan(to_radians(degrees))

      def to_degrees(radians)                   = radians.to_f * 180 / ::Math::PI

      def to_radians(degrees)                   = degrees.to_f / 180 * ::Math::PI

      def vertical?(degrees, precision = nil)   = zero?(degrees % 90.0, precision:)
    end

    extend Math
  end
end
