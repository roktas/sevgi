# frozen_string_literal: true

module Sevgi
  module Function
    # Numeric and trigonometric methods promoted to {Sevgi::F}. This module owns the public thread-local
    # {Math.precision} configuration but is not otherwise a consumer mixin contract.
    module Math
      # Default decimal precision used by approximate comparisons.
      PRECISION = 6

      PRECISION_KEY = :sevgi_function_math_precision
      QUADRANT_COSINES = [1.0, 0.0, -1.0, 0.0].freeze
      QUADRANT_SINES = [0.0, 1.0, 0.0, -1.0].freeze

      private_constant :PRECISION_KEY, :QUADRANT_COSINES, :QUADRANT_SINES

      # Returns the current thread's default numeric precision.
      # @return [Integer] current thread precision, or {PRECISION} when no override is set
      def self.precision
        precision = Thread.current.thread_variable_get(PRECISION_KEY)

        precision.nil? ? PRECISION : precision
      end

      # Sets or clears the current thread's default numeric precision.
      # @param precision [Integer, nil] precision override, or nil to return to {PRECISION}
      # @return [Integer, nil] assigned precision
      # @raise [Sevgi::ArgumentError] when precision is not an Integer or nil
      def self.precision=(precision)
        unless precision.nil? || precision.is_a?(::Integer)
          ArgumentError.("Precision must be an Integer or nil: #{precision.inspect}")
        end

        Thread.current.thread_variable_set(PRECISION_KEY, precision)
      end

      # Returns the inverse cosine in degrees.
      # @param value [Numeric] cosine value
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when value is not a finite real number
      # @raise [::Math::DomainError] when value is outside -1..1
      def acos(value) = to_degrees(::Math.acos(finite_real(:value, value)))

      # Returns the inverse cotangent in degrees.
      # @param value [Numeric] cotangent value
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when value is not a finite real number
      def acot(value) = 90.0 - to_degrees(::Math.atan(finite_real(:value, value)))

      # Rounds a float with an explicit or thread-local precision.
      # @param float [Numeric] value to round
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Numeric] rounded value
      # @raise [Sevgi::ArgumentError] when value is not finite real or precision is not an Integer or nil
      def approx(float, precision = nil)
        precision = precision.nil? ? Function::Math.precision : valid_precision(precision)
        valid_real(:value, float).round(precision)
      end

      # Returns the inverse sine in degrees.
      # @param value [Numeric] sine value
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when value is not a finite real number
      # @raise [::Math::DomainError] when value is outside -1..1
      def asin(value) = to_degrees(::Math.asin(finite_real(:value, value)))

      # Returns the inverse tangent in degrees.
      # @param value [Numeric] tangent value
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when value is not a finite real number
      def atan(value) = to_degrees(::Math.atan(finite_real(:value, value)))

      # Returns the quadrant-aware inverse tangent in degrees.
      # @param y [Numeric] y component
      # @param x [Numeric] x component
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when an operand is not a finite real number
      def atan2(y, x) = to_degrees(::Math.atan2(finite_real(:y, y), finite_real(:x, x)))

      # Returns the cosine of an angle expressed in degrees. Integer quarter turns return exact `-1.0`, `0.0`, or
      # `1.0`; other angles use Ruby's floating-point Math implementation.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when degrees is not a finite real number
      def cos(degrees)
        degrees = finite_real(:degrees, degrees)
        quadrant_value(degrees, QUADRANT_COSINES) { ::Math.cos(radians(degrees)) }
      end

      # Returns the cotangent of an angle expressed in degrees.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when degrees is not a finite real number
      def cot(degrees) = 1.0 / ::Math.tan(to_radians(degrees))

      # Counts complete divisions in a length.
      # @param length [Numeric] finite real total length
      # @param division [Numeric] finite real, non-zero division size
      # @return [Integer]
      # @raise [Sevgi::ArgumentError] when an operand is not a finite Numeric or division is zero
      def count(length, division)
        length = finite_real(:length, length)
        divisor = finite_real(:division, division)
        ArgumentError.("Division must not be zero") if divisor.zero?

        (length / divisor).to_i
      end

      # Compares two numeric values after approximate rounding.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      # @raise [Sevgi::ArgumentError] when an operand is not finite real or precision is invalid
      def eq?(left, right, precision: nil) = approx(left, precision) == approx(right, precision)

      # Checks whether the rounded left operand is greater than or equal to the rounded right operand.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      # @raise [Sevgi::ArgumentError] when an operand is not finite real or precision is invalid
      def ge?(left, right, precision: nil) = approx(left, precision) >= approx(right, precision)

      # Checks whether the rounded left operand is greater than the rounded right operand.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      # @raise [Sevgi::ArgumentError] when an operand is not finite real or precision is invalid
      def gt?(left, right, precision: nil) = approx(left, precision) > approx(right, precision)

      # Checks whether the rounded left operand is less than or equal to the rounded right operand.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      # @raise [Sevgi::ArgumentError] when an operand is not finite real or precision is invalid
      def le?(left, right, precision: nil) = approx(left, precision) <= approx(right, precision)

      # Checks whether the rounded left operand is less than the rounded right operand.
      # @param left [Numeric] left operand
      # @param right [Numeric] right operand
      # @param precision [Integer, nil] explicit precision, or nil to use {Math.precision}
      # @return [Boolean]
      # @raise [Sevgi::ArgumentError] when an operand is not finite real or precision is invalid
      def lt?(left, right, precision: nil) = approx(left, precision) < approx(right, precision)

      # Rounds a value only when precision is present.
      # @param float [Numeric] value to round
      # @param precision [Integer, nil] explicit precision, or nil to return float unchanged
      # @return [Numeric]
      # @raise [Sevgi::ArgumentError] when value is not finite real or precision is not an Integer or nil
      def round(float, precision)
        number = valid_real(:value, float)
        precision.nil? ? number : number.round(valid_precision(precision))
      end

      # Returns the sine of an angle expressed in degrees. Integer quarter turns return exact `-1.0`, `0.0`, or `1.0`;
      # other angles use Ruby's floating-point Math implementation.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when degrees is not a finite real number
      def sin(degrees)
        degrees = finite_real(:degrees, degrees)
        quadrant_value(degrees, QUADRANT_SINES) { ::Math.sin(radians(degrees)) }
      end

      # Returns the tangent of an angle expressed in degrees.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when degrees is not a finite real number
      def tan(degrees) = ::Math.tan(to_radians(degrees))

      # Converts radians to degrees.
      # @param radians [Numeric] angle in radians
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when radians is not a finite real number
      def to_degrees(radians) = finite_real(:radians, radians) * 180 / ::Math::PI

      # Converts degrees to radians.
      # @param degrees [Numeric] angle in degrees
      # @return [Float]
      # @raise [Sevgi::ArgumentError] when degrees is not a finite real number
      def to_radians(degrees) = radians(finite_real(:degrees, degrees))

      # Runs a block with a current-thread precision override.
      # @param precision [Integer, nil] scoped precision, or nil to use {PRECISION}
      # @yield block executed with the scoped precision
      # @yieldreturn [Object]
      # @return [Object] block return value
      # @raise [Sevgi::ArgumentError] when no block is given
      # @raise [Sevgi::ArgumentError] when precision is not an Integer or nil
      # @example Compare values under a temporary precision
      #   Sevgi::F.with_precision(2) { Sevgi::F.eq?(1.001, 1.0) } # => true
      #   Sevgi::Function::Math.precision # => 6
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
      # @raise [Sevgi::ArgumentError] when value is not finite real or precision is invalid
      def zero?(value, precision: nil) = eq?(value, 0.0, precision:)

      private

      def finite_real(field, value)
        unless value.is_a?(::Numeric) && !value.is_a?(::Complex)
          ArgumentError.("#{field} must be a finite real Numeric: #{value.inspect}")
        end

        number = begin
          value.to_f
        rescue ::StandardError => e
          ArgumentError.("#{field} must be a finite real Numeric: #{value.inspect} (#{e.message})")
        end

        ArgumentError.("#{field} must be finite: #{value.inspect}") unless number.is_a?(::Float) && number.finite?

        number
      end

      def quadrant_value(degrees, values)
        turn = degrees % 360
        return yield unless (turn % 90).zero?

        values[(turn / 90).to_i]
      end

      def radians(degrees) = degrees / 180 * ::Math::PI

      def valid_precision(precision)
        return precision if precision.is_a?(::Integer)

        ArgumentError.("Precision must be an Integer or nil: #{precision.inspect}")
      end

      def valid_real(field, value)
        finite_real(field, value)
        value
      end

    end

    extend Math
  end
end
