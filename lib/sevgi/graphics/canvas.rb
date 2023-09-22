# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Graphics
    class Canvas
      extend Forwardable
      def_delegators :@margin, *Margin.members
      def_delegators :@dim,    *Dim.members

      attr_reader :dim, :margin, :content

      def initialize(width:, height:, unit: "mm", margins: [])
        @dim    = Dim[width, height, unit]
        @margin = Margin[*margins]

        compute
        freeze
      end

      def attributes     = { **viewport, viewBox: viewbox }

      def rect           = content.rect

      def viewport       = { width: "#{width}#{unit}", height: "#{height}#{unit}" }

      def viewbox        = F.prettify(-margin.left, -margin.top, width, height).join(" ")

      def with(*margins) = margins.empty? ? self : self.class.new(**dim.to_h, margins:)

      private

      def compute
        @content = dim.with(width: width - margin.left - margin.right, height: height - margin.top - margin.bottom)
      end

      class << self
        def call(arg = Paper.default, *)
          case arg
          when Canvas then arg
          when Symbol then new(**Paper[arg].to_h)
          else             ArgumentError.("Argument must be a Symbol or Canvas instance: #{arg}")
          end => canvas

          canvas.with(*)
        end
      end
    end
  end
end
