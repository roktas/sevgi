# frozen_string_literal: true

module Sevgi
  module Graphics
    Margin = Data.define(:top, :right, :bottom, :left) do
      include Comparable

      def initialize(top: nil, right: nil, bottom: nil, left: nil)
        super(**normalize(top, right, bottom, left))
      end

      def <=>(other) = deconstruct <=> other.deconstruct

      def adjust(h, v) = self.class[top + v, right + h, bottom + v, left + h]

      def eql?(other) = self.class == other.class && deconstruct == other.deconstruct

      def hash = [self.class, *deconstruct].hash

      def horizontal = left + right

      def vertical = top + bottom

      alias_method :==, :eql?
      alias_method :to_a, :deconstruct

      def self.margin(array)
        self[
          *(array = Array(array)[0...(size = Margin.members.size)]).fill(nil, array.size, size - array.size)
        ]
      end

      def self.zero = (@zero ||= self[0.0, 0.0, 0.0, 0.0])

      private

      def normalize(top, right, bottom, left)
        values = [top, right, bottom, left]

        Margin.members.zip(values_for(values.compact.size, values).map { Float(it) }).to_h
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
