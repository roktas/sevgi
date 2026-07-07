# frozen_string_literal: true

module Sevgi
  module Function
    # Numeric and trigonometric helpers used by geometry and DSL code.
    module Math
      # Default decimal precision used by approximate comparisons.
      PRECISION = 6

      PRECISION_KEY = :sevgi_function_math_precision

      private_constant :PRECISION_KEY

      # Returns the current thread's default numeric precision.
      # @return [Integer] current thread precision, or {PRECISION} when no override is set
      def self.precision
        precision = Thread.current.thread_variable_get(PRECISION_KEY)

        precision.nil? ? PRECISION : precision
      end

      # Sets or clears the current thread's default numeric precision.
      # @param precision [Integer, nil] precision override, or nil to return to {PRECISION}
      # @return [Integer, nil] assigned precision
      def self.precision=(precision)
        Thread.current.thread_variable_set(PRECISION_KEY, precision)
      end

      # Returns the inverse cosine in degrees.
      # @param value [Numeric] cosine value
      # @return [Float]
      # @raise [Math::DomainError] when value is outside -1..1
      def acos(value) = to_degrees(::Math.acos(value))

      # Returns the inverse cotangent in degrees.
      # @param value [Numeric] cotangent value
      # @return [Float]
      def acot(value) = 90.0 - to_degrees(::Math.atan(value))

      # Rounds a float with an explicit or thread-local precision.
      # @param float [Numeric] value to round
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Numeric] rounded value
      # @raise [TypeError] when float cannot be rounded
      def approx(float, precision = nil)
        float.round(precision.nil? ? Function::Math.precision : precision)
      end

      # Returns the inverse sine in degrees.
      # @param value [Numeric] sine value
      # @return [Float]
      # @raise [Math::DomainError] when value is outside -1..1
      def asin(value) = to_degrees(::Math.asin(value))

      # Returns the inverse tangent in degrees.
      # @param value [Numeric] tangent value
      # @return [Float]
      def atan(value) = to_degrees(::Math.atan(value))

      # Returns the quadrant-aware inverse tangent in degrees.
      # @param y [Numeric] y component
      # @param x [Numeric] x component
      # @return [Float]
      def atan2(y, x) = to_degrees(::Math.atan2(y, x))

      # Returns the cosine of an angle expressed in degrees.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      def cos(degrees) = ::Math.cos(to_radians(degrees))

      # Returns the cotangent of an angle expressed in degrees.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      def cot(degrees) = 1.0 / ::Math.tan(to_radians(degrees))

      # Counts complete divisions in a length.
      # @param length [Numeric] total length
      # @param division [Numeric] division size
      # @return [Integer]
      # @raise [ZeroDivisionError] when division is zero
      def count(length, division) = (length / division.to_f).to_i

      # Compares two numeric values after approximate rounding.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      def eq?(left, right, precision: nil) = approx(left, precision) == approx(right, precision)

      # Checks whether the rounded left operand is greater than or equal to the rounded right operand.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      def ge?(left, right, precision: nil) = approx(left, precision) >= approx(right, precision)

      # Checks whether the rounded left operand is greater than the rounded right operand.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      def gt?(left, right, precision: nil) = approx(left, precision) > approx(right, precision)

      # Checks whether the rounded left operand is less than or equal to the rounded right operand.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      def le?(left, right, precision: nil) = approx(left, precision) <= approx(right, precision)

      # Checks whether the rounded left operand is less than the rounded right operand.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      def lt?(left, right, precision: nil) = approx(left, precision) < approx(right, precision)

      # Rounds a value only when precision is present.
      # @param float [Numeric] value to round
      # @param precision [Integer, nil] explicit precision, or nil to return float unchanged
      # @return [Numeric]
      def round(float, precision) = precision ? float.round(precision) : float

      # Returns the sine of an angle expressed in degrees.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      def sin(degrees) = ::Math.sin(to_radians(degrees))

      # Returns the tangent of an angle expressed in degrees.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      def tan(degrees) = ::Math.tan(to_radians(degrees))

      # Converts radians to degrees.
      # @param radians [Numeric] angle in radians
      # @return [Float]
      def to_degrees(radians) = radians.to_f * 180 / ::Math::PI

      # Converts degrees to radians.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      def to_radians(degrees) = degrees.to_f / 180 * ::Math::PI

      # Runs a block with a current-thread precision override.
      # @param precision [Integer, nil] scoped precision, or nil to use {PRECISION}
      # @yield block executed with the scoped precision
      # @yieldreturn [Object]
      # @return [Object] block return value
      # @raise [Sevgi::ArgumentError] when no block is given
      def with_precision(precision, &block)
        ArgumentError.("Block required") unless block

        previous = Thread.current.thread_variable_get(PRECISION_KEY)
        Function::Math.precision = precision
        block.call
      ensure
        Function::Math.precision = previous if block
      end

      # Checks whether a value is approximately zero.
      # @param value [Numeric] value to check
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      def zero?(value, precision: nil) = eq?(value, 0.0, precision:)
    end

    extend Math
  end
end
