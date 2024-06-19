# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Graphics
    class Canvas
      extend Forwardable
      def_delegators :@margin, *Margin.members
      def_delegators :@size,   *Size.members

      attr_reader :size, :margin, :inner

      def initialize(width:, height:, unit: "mm", name: :custom, margins: [])
        @size   = Size[width, height, unit, name]
        @margin = Margin[*margins]

        compute
        freeze
      end

      def attributes      = { **viewport, viewBox: viewbox }

      def conforming(...) = self.class.conforming(self, ...)

      def viewport        = { width: "#{width}#{unit}", height: "#{height}#{unit}" }

      def viewbox         = prettify(-margin.left, -margin.top, width, height).join(" ")

      def with(*margins)  = margins.empty? ? self : self.class.new(**size.to_h, margins:)

      private

        def compute
          @inner = size.with(width: width - margin.left - margin.right, height: height - margin.top - margin.bottom)
        end

        def prettify(*floats)
          floats.map { (i = it.to_i) == it.to_f ? i : it }
        end

      def self.call(arg = Size.default, *)
        canvas(arg).with(*)
      end

      class << self
        private

          def canvas(arg)
            case arg
            when Canvas             then arg
            when Size               then new(**arg.to_h)
            when ::Symbol, ::String then new(**Size.public_send(arg).to_h)
            else                    ArgumentError.("Argument must be a Symbol (size) or Canvas instance: #{arg}")
            end
          end
      end
    end
  end
end
