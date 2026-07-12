# frozen_string_literal: true

module Sevgi
  module Geometry
    # Validates numeric inputs that can be represented as finite Floats.
    # @api private
    module Real
      # Coerces a public numeric value to a finite Float.
      # @param field [Symbol, String] coordinate or component name
      # @param value [Object] value to coerce
      # @return [Float] finite float value
      # @raise [Sevgi::Geometry::Error] when value is not a Numeric, cannot be converted to Float, or is not finite
      def self.[](field, value)
        unless value.is_a?(::Numeric) && !value.is_a?(::Complex)
          Error.("Geometry #{field} must be a finite real Numeric: #{value.inspect}")
        end

        number = coerce(field, value)

        unless number.is_a?(::Float) && number.finite?
          Error.("Geometry #{field} must be finite: #{value.inspect}")
        end

        number
      end

      def self.coerce(field, value)
        value.to_f
      rescue ::StandardError => e
        Error.("Geometry #{field} must be a finite real Numeric: #{value.inspect} (#{e.message})")
      end

      private_class_method :coerce
    end

    private_constant :Real

    # Coerces array-like geometry inputs into typed tuple objects.
    # @api private
    module Tuple
      # Coerces an argument into the requested tuple class.
      # @param klass [Class] tuple class such as {Point} or {Segment}
      # @param arg [Array<Numeric>, Object] tuple instance or two-element numeric array
      # @return [Object] tuple instance
      # @raise [Sevgi::Geometry::Error] when arg cannot be coerced
      def self.[](klass, arg)
        case arg
        when ::Array
          Error.("Array must have 2 elements: #{arg.inspect}") unless arg.size == 2

          klass.send(:new, *arg)
        when klass
          arg
        else
          Error.("Must be an Array or #{klass}: #{arg}")
        end
      end
    end

    private_constant :Tuple

    # Coerces multiple array-like geometry inputs into typed tuple objects.
    # @api private
    module Tuples
      # Coerces arguments into the requested tuple class.
      # @param klass [Class] tuple class such as {Point} or {Segment}
      # @param args [Array<Array<Numeric>, Object>] tuple instances or two-element numeric arrays
      # @return [Array<Object>] tuple instances
      # @raise [Sevgi::Geometry::Error] when any argument cannot be coerced
      def self.[](klass, *args) = args.map { Tuple[klass, it] }
    end

    private_constant :Tuples
  end
end
