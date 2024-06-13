# frozen_string_literal: true

module Sevgi
  module Function
    module Math
      @precision = PRECISION = 6

      class << self
        attr_accessor :precision
      end

      def acos(value)                           = to_degrees(::Math.acos(value))

      def acot(value)                           = 90.0 - to_degrees(::Math.atan(value))

      def acute!(degrees, precision: nil)       = (acute?(degrees, precision:) or raise(ArgumentError, "Angle must >= 0 and <= 90: #{degrees}"))

      def acute?(degrees, precision: nil)       = le?(degrees, 90.0, precision:) && ge?(degrees, 0.0, precision:)

      def array_approx(array, precision = nil)  = array.map { approx(it, precision) } # TODO: xxx

      def approx(float, precision = nil)        = float.round(precision || Function::Math.precision)

      def asin(value)                           = to_degrees(::Math.asin(value))

      def atan(value)                           = to_degrees(::Math.atan(value))

      def atan2(y, x)                           = to_degrees(::Math.atan2(y, x))

      def complement(degrees)                   = 90.0 - degrees

      def cos(degrees)                          = ::Math.cos(to_radians(degrees))

      def cot(degrees)                          = 1.0 / ::Math.tan(to_radians(degrees))

      def count(length, division)               = (length / division.to_f).to_i

      def array_eq?(left, right, precision: nil) = array_approx(left, precision) == array_approx(right, precision) # TODO: xxx

      def eq?(left, right, precision: nil)      = approx(left, precision) == approx(right, precision)

      def ge?(left, right, precision: nil)      = approx(left, precision) >= approx(right, precision)

      def golden                                = @golden ||= ((1.0 + ::Math.sqrt(5)) / 2.0)

      def gt?(left, right, precision: nil)      = approx(left, precision) > approx(right, precision)

      def horizontal?(degrees, precision = nil) = zero?(degrees % 180.0, precision:)

      def le?(left, right, precision: nil)      = approx(left, precision) <= approx(right, precision)

      def lt?(left, right, precision: nil)      = approx(left, precision) < approx(right, precision)

      def nangle(degrees)                       = degrees - 90.0

      def nonzero?(...)                         = !zero?(...)

      def obtuse!(degrees, precision: nil)      = (obtuse?(degrees, precision:) or raise(ArgumentError, "Angle must >= 90 and <= 180: #{degrees}"))

      def obtuse?(degrees, precision: nil)      = le?(degrees, 180.0, precision:) && ge?(degrees, 90.0, precision:)

      def ordinary!(degrees, precision: nil)    = (ordinary?(degrees, precision:) or raise(ArgumentError, "Angle must >= 0 and <= 180: #{degrees}"))

      def ordinary?(degrees, precision: nil)    = le?(degrees, 180.0, precision:) && ge?(degrees, 0.0, precision:)

      def round(float, precision)               = precision ? float.round(precision) : float

      def sin(degrees)                          = ::Math.sin(to_radians(degrees))

      def sqrt2                                 = @sqrt2  ||= ::Math.sqrt(2)

      def sqrt2h                                = @sqrt2h ||= (sqrt2 / 2.0)

      def tan(degrees)                          = ::Math.tan(to_radians(degrees))

      def to_degrees(radians)                   = radians.to_f * 180 / ::Math::PI

      def to_radians(degrees)                   = degrees.to_f / 180 * ::Math::PI

      def unordered_between?(item, interval)    = item.between?(interval.min, interval.max)

      def vertical?(degrees, precision = nil)   = zero?(degrees % 90.0, precision:)

      def zero?(value, precision: nil)          = eq?(value, 0.0, precision:)
    end

    extend Math
  end
end
