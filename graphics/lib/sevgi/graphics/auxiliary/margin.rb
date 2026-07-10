# frozen_string_literal: true

module Sevgi
  module Graphics
    # Four-sided margin with CSS-like shorthand normalization.
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
      # @param top [Numeric, nil] top value or all-sides shorthand
      # @param right [Numeric, nil] right value or horizontal shorthand
      # @param bottom [Numeric, nil] bottom value
      # @param left [Numeric, nil] left value
      # @return [void]
      def initialize(top: nil, right: nil, bottom: nil, left: nil)
        super(**normalize(top, right, bottom, left))
      end

      # Compares margins by top, right, bottom, then left.
      # @param other [Sevgi::Graphics::Margin] margin to compare
      # @return [Integer, nil]
      def <=>(other) = deconstruct <=> other.deconstruct

      # Returns a margin inflated horizontally and vertically.
      # @param h [Numeric] horizontal addition
      # @param v [Numeric] vertical addition
      # @return [Sevgi::Graphics::Margin]
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

      alias_method :==, :eql?
      alias_method :to_a, :deconstruct

      # Builds a margin from an array-like shorthand.
      # @param array [Object] value converted with Array()
      # @return [Sevgi::Graphics::Margin]
      def self.margin(array)
        self[
          *(array = Array(array)[0...(size = Margin.members.size)]).fill(nil, array.size, size - array.size)
        ]
      end

      # Returns a zero margin.
      # @return [Sevgi::Graphics::Margin]
      def self.zero = (@zero ||= self[0.0, 0.0, 0.0, 0.0])

      private

      def normalize(top, right, bottom, left)
        values = [top, right, bottom, left]

        Margin
          .members
          .zip(
            values_for(values.compact.size, values).map do |value|
              Scalar.finite(value, context: "margin", field: :value, nonnegative: true)
            end
          )
          .to_h
      end

      def values_for(size, values)
        top, right, bottom = values

        [
          [0, 0, 0, 0],
          [top, top, top, top],
          [top, right, top, right],
          [top, right, bottom, right]
        ][size] ||
          values
      end
    end
  end
end
