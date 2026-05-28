# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Graphics
    class Canvas
      def self.call(arg = Undefined, **kwargs)
        case arg
        when Undefined
          new(**kwargs)
        when ::Symbol, ::String
          new(**Paper.public_send(arg).to_h, **kwargs)
        else
          ArgumentError.("Argument must be a Paper symbol: #{arg}")
        end
      end

      extend Forwardable

      def_delegators :@margin, *Margin.members
      def_delegators :@size, *Paper.members

      attr_reader :size, :margin, :inner

      def initialize(width:, height:, unit: "mm", name: :custom, margins: [])
        @size = Paper[width, height, unit, name]
        @margin = Margin[*margins]

        compute
        freeze
      end

      def attributes(...) = {**viewport, viewBox: viewbox(...)}

      def conforming(...) = self.class.conforming(self, ...)

      def viewport = {width: "#{width}#{unit}", height: "#{height}#{unit}"}

      def viewbox(origin = Undefined) = prettify(*originate(origin), width, height).join(" ")

      def with(**kwargs) = self.class.new(**size.to_h, margins: kwargs.fetch(:margins, margin.to_a))

      private

      def compute
        @inner = size.with(width: width - margin.left - margin.right, height: height - margin.top - margin.bottom)
      end

      def originate(origin)
        case origin
        when Undefined
          [-margin.left, -margin.top]
        when ::Numeric, ::NilClass
          [origin.to_f, origin.to_f]
        when ::Array
          pair(origin)
        else
          ArgumentError.("Canvas origin must be an Array")
        end
      end

      def prettify(*floats)
        floats.map { (it % 1).zero? ? it.to_i : it }
      end

      def pair(array)
        array.size == 2 ? array.map(&:to_f) : ArgumentError.("Argument must be an Array of size 2")
      end
    end
  end
end
