# frozen_string_literal: true

module Sevgi
  module Geometry
    # Validates finite real numeric inputs for geometry primitives.
    # @api private
    module Real
      # Coerces a public numeric value to Float.
      # @param field [Symbol, String] coordinate or component name
      # @param value [Object] value to coerce
      # @return [Float] finite float value
      # @raise [Sevgi::Geometry::Error] when value is not a finite Numeric
      def self.[](field, value)
        unless value.is_a?(::Numeric)
          Error.("Geometry #{field} must be a finite Numeric: #{value.inspect}")
        end

        value.to_f.tap do |number|
          Error.("Geometry #{field} must be finite: #{value.inspect}") unless number.finite?
        end
      end
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
