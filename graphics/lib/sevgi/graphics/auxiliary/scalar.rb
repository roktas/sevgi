# frozen_string_literal: true

module Sevgi
  module Graphics
    # Validates finite real numeric values used by Graphics APIs.
    # @api private
    module Scalar
      # Converts one finite real value.
      # @param value [Numeric] value to validate
      # @param context [String] error context
      # @param field [Symbol, Integer] field name or position
      # @param positive [Boolean] require a strictly positive value
      # @param nonnegative [Boolean] require a non-negative value
      # @return [Float] validated value
      # @raise [Sevgi::ArgumentError] when value is not a finite real number in the requested range
      def self.finite(value, context:, field:, positive: false, nonnegative: false)
        invalid(context, field, value) unless real?(value)

        number = Float(value)
        invalid(context, field, value) unless valid?(number, positive:, nonnegative:)

        number
      rescue ::ArgumentError, ::RangeError, ::TypeError
        invalid(context, field, value)
      end

      # Converts one finite real value to an SVG number.
      # @param value [Numeric] value to validate
      # @param context [String] error context
      # @param field [Symbol, Integer] field name or position
      # @param positive [Boolean] require a strictly positive value
      # @param nonnegative [Boolean] require a non-negative value
      # @return [Integer, Float] normalized number with integral values represented as Integer
      # @raise [Sevgi::ArgumentError] when value is not a finite real number
      def self.number(value, context:, field:, positive: false, nonnegative: false)
        if value.is_a?(::Integer)
          invalid(context, field, value) unless valid?(value, positive:, nonnegative:)
          return value
        end

        value = finite(value, context:, field:, positive:, nonnegative:)
        value == value.to_i ? value.to_i : value
      end

      # Converts indexed finite real values to SVG numbers.
      # @param values [Array<Numeric>] values to normalize
      # @param context [String] error context
      # @return [Array<(Integer, Float)>] normalized SVG numbers
      # @raise [Sevgi::ArgumentError] when a value is not a finite real number
      def self.numbers(values, context:)
        values.each_with_index.map { |value, index| number(value, context:, field: index) }
      end

      def self.real?(value) = value.is_a?(::Numeric) && !value.is_a?(::Complex)

      def self.valid?(number, positive:, nonnegative:)
        number.finite? && (!positive || number.positive?) && (!nonnegative || number >= 0)
      end

      def self.invalid(context, field, value) = ArgumentError.("Invalid #{context} #{field}: #{value.inspect}")

      private_class_method :invalid, :real?, :valid?
    end

    private_constant :Scalar
  end
end
