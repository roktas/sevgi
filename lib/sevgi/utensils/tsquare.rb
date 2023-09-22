# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Utensils
    class Tsquare
      extend Forwardable
      def_delegators :@h, :halve, :major, :minor

      def_delegator  :@h, :length, :width
      def_delegator  :@v, :length, :height

      attr_reader :h, :v

      def initialize(hruler:, vruler:)
        @h = hruler
        @v = vruler
      end

      def canvas = Graphics::Canvas.new(**Dim[h.brut, v.brut].to_h, margins: Margin[v.space / 2.0, h.space / 2.0].to_a)

      def grid   = Grid.new(self)

      alias_method :unit, :minor
    end
  end
end
