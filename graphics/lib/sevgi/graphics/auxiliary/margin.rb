# frozen_string_literal: true

module Sevgi
  module Graphics
    # Four-sided margin with CSS-like shorthand normalization.
    # @!parse
    #   class Margin
    #     # Creates a margin from one to four CSS-like shorthand values.
    #     # @param top [Numeric, Sevgi::Undefined] top value or all-sides shorthand
    #     # @param right [Numeric, Sevgi::Undefined] right value or horizontal shorthand
    #     # @param bottom [Numeric, Sevgi::Undefined] bottom value
    #     # @param left [Numeric, Sevgi::Undefined] left value
    #     # @return [Sevgi::Graphics::Margin]
    #     # @raise [Sevgi::ArgumentError] when a supplied value is not a finite, non-negative real number
    #     # @example Create a vertical and horizontal margin
    #     #   Sevgi::Graphics::Margin[5, 10]
    #     def self.[](top = nil, right = nil, bottom = nil, left = nil); end
    #   end
    Margin = Data.define(:top, :right, :bottom, :left) do
      include Comparable

      # @!attribute [r] top
      #   @return [Float] top margin
      # @!attribute [r] right
      #   @return [Float] right margin
      # @!attribute [r] bottom
      #   @return [Float] bottom margin
      # @!attribute [r] left
      #   @return [Float] left margin

      # Creates a margin from one to four shorthand values. Values must be finite real numbers greater than or equal to
      # zero.
      # @param top [Numeric, Sevgi::Undefined] top value or all-sides shorthand
      # @param right [Numeric, Sevgi::Undefined] right value or horizontal shorthand
      # @param bottom [Numeric, Sevgi::Undefined] bottom value
      # @param left [Numeric, Sevgi::Undefined] left value
      # @return [void]
      # @raise [Sevgi::ArgumentError] when a supplied margin is not a finite, non-negative real number
      def initialize(top: Undefined, right: Undefined, bottom: Undefined, left: Undefined)
        super(**normalize(top, right, bottom, left))
      end

      # Compares margins by top, right, bottom, then left.
      # @param other [Object] margin to compare
      # @return [Integer, nil] comparison result, or nil for a non-Margin operand
      def <=>(other)
        deconstruct <=> other.deconstruct if other.is_a?(self.class)
      end

      # Returns a margin inflated horizontally and vertically.
      # @param h [Numeric] horizontal addition
      # @param v [Numeric] vertical addition
      # @return [Sevgi::Graphics::Margin]
      # @raise [Sevgi::ArgumentError] when the adjusted margin is negative or not finite
      def adjust(h, v) = self.class[top + v, right + h, bottom + v, left + h]

      # Reports strict margin equality.
      # @param other [Object] object to compare
      # @return [Boolean]
      def eql?(other) = self.class == other.class && deconstruct == other.deconstruct

      # Returns a hash compatible with strict equality.
      # @return [Integer]
      def hash = [self.class, *deconstruct].hash

      # Returns total horizontal margin.
      # @return [Float]
      def horizontal = left + right

      # Returns total vertical margin.
      # @return [Float]
      def vertical = top + bottom

      # Reports whether all four margin sides are zero.
      # @return [Boolean]
      def zero? = top.zero? && right.zero? && bottom.zero? && left.zero?

      alias_method :==, :eql?

      # Returns margin values in top, right, bottom, left order.
      # @return [Array<Float>]
      alias_method :to_a, :deconstruct

      # Returns a zero margin.
      # @return [Sevgi::Graphics::Margin]
      def self.zero = (@zero ||= self[0.0, 0.0, 0.0, 0.0])

      private

      def normalize(top, right, bottom, left)
        Margin
          .members
          .zip(
            values_for(top, right, bottom, left).map do |value|
              Scalar.finite(value, context: "margin", field: :value, nonnegative: true)
            end
          )
          .to_h
      end

      def values_for(top, right, bottom, left)
        values = [top, right, bottom, left]
        indices = {
          [true, false, false, false] => [0, 0, 0, 0],
          [true, true, false, false] => [0, 1, 0, 1],
          [true, true, true, false] => [0, 1, 2, 1]
        }[values.map { !it.equal?(Undefined) }]

        (indices ? values.values_at(*indices) : values).map { it.equal?(Undefined) ? 0 : it }
      end
    end
  end
end
