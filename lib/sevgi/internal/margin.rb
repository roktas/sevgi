# frozen_string_literal: true

module Sevgi
  Margin = Data.define(:top, :right, :bottom, :left) do
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

    alias_method :to_a, :deconstruct

    class << self
      def zero = (@zero ||= self[0.0, 0.0, 0.0, 0.0])
    end
  end
end
