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

      # Validates and preserves one finite real value.
      # @param value [Numeric] value to validate
      # @param context [String] error context
      # @param field [Symbol, Integer] field name or position
      # @return [Numeric] original value
      # @raise [Sevgi::ArgumentError] when value is not a finite real number
      def self.validate(value, context:, field:)
        finite(value, context:, field:)
        value
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
