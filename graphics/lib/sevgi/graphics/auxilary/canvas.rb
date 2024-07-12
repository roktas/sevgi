# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Graphics
    class Canvas
      def self.call(arg = Undefined, **kwargs)
        case arg
        when Undefined          then new(**kwargs)
        when ::Symbol, ::String then new(**Size.public_send(arg).to_h, **kwargs)
        else                    ArgumentError.("Argument must be a Size symbol: #{arg}")
        end
      end

      extend Forwardable

      def_delegators :@margin, *Margin.members
      def_delegators :@size,   *Size.members

      attr_reader :size, :margin, :origin, :inner

      def initialize(width:, height:, origin: Undefined, unit: "mm", name: :custom, margins: [])
        @size   = Size[width, height, unit, name]
        @margin = Margin[*margins]
        @origin = originate(origin)

        compute
        freeze
      end

      def attributes      = { **viewport, viewBox: viewbox }

      def conforming(...) = self.class.conforming(self, ...)

      def viewport        = { width: "#{width}#{unit}", height: "#{height}#{unit}" }

      def viewbox         = prettify(*origin, width, height).join(" ")

      def with(**kwargs)
        self.class.new(**size.to_h, margins: kwargs.fetch(:margins, margin.to_a), origin: kwargs.fetch(:origin, Undefined))
      end

      private

        def compute
          @inner = size.with(width: width - margin.left - margin.right, height: height - margin.top - margin.bottom)
        end

        def originate(origin)
          case origin
          when Undefined             then [ -margin.left, -margin.top ]
          when ::Numeric, ::NilClass then [ origin.to_f, origin.to_f  ]
          when ::Array               then pair(origin)
          else                            ArgumentError.("Canvas origin must be an Array")
          end
        end

        def prettify(*floats)
          floats.map { (i = it.to_i) == it.to_f ? i : it }
        end

        def pair(array)
          array.size == 2 ? array.map(&:to_f) : ArgumentError.("Argument must be an Array of size 2")
        end
    end
  end
end
