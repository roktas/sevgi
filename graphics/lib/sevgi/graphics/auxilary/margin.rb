# frozen_string_literal: true

module Sevgi
  module Graphics
    Margin = Data.define(:top, :right, :bottom, :left) do
      include Comparable

      def initialize(top: nil, right: nil, bottom: nil, left: nil)
        case [ top, right, bottom, left ]
        in Numeric,  Numeric,  Numeric,  Numeric  then # nop
        in Numeric,  Numeric,  Numeric,  NilClass then left                     = right
        in Numeric,  Numeric,  NilClass, NilClass then bottom, left             = top, right
        in Numeric,  NilClass, NilClass, NilClass then bottom, left, right      = top, top, top
        in NilClass, NilClass, NilClass, NilClass then top, bottom, left, right = 0, 0, 0, 0
        end

        super(top: Float(top), right: Float(right), bottom: Float(bottom), left: Float(left))
      end

      def <=>(other)   = deconstruct <=> other.deconstruct

      def change(h, v) = self.class[top + v, right + h, bottom + v, left + h]

      def eql?(other)  = self.class == other.class && deconstruct == other.deconstruct

      def hash         = [ self.class, *deconstruct ].hash

      def htotal       = left + right

      def vtotal       = top + bottom

      alias_method :==,   :eql?
      alias_method :to_a, :deconstruct

      def self.margin(array)
        self[
          *(array = Array(array)[0...(size = Margin.members.size)]).fill(nil, array.size, size - array.size)
        ]
      end

      def self.zero = (@zero ||= self[0.0, 0.0, 0.0, 0.0])
    end
  end
end
