# frozen_string_literal: true

# rubocop:disable Layout/ExtraSpacing,Style/TrailingCommaInHashLiteral

module Sevgi
  module Graphics
    Paper = Data.define(:width, :height, :unit, :name) do
      include Comparable

      def initialize(width:, height:, unit: "mm", name: :custom)
        super(width: Float(width), height: Float(height), unit: unit.to_sym, name: name.to_sym)
      end

      def <=>(other)  = deconstruct <=> other.deconstruct

      def eql?(other) = self.class == other.class && deconstruct == other.deconstruct

      def hash        = [ self.class, *deconstruct ].hash

      def longest     = [ width, height ].max

      def shortest    = [ width, height ].min

      alias_method :==,   :eql?

      def self.define!(name, ...)
        raise ArgumentError, "Paper already defined: #{name}" if exist?(name)

        define(name, ...)
      end

      def self.exist?(name) = respond_to?(name)

      def self.define(name, **spec)
        singleton_class.attr_reader name
        instance_variable_set("@#{name}", new(name:, **spec))
      end

      {
        a0:        [ 841,  1189, "mm" ],
        a1:        [ 594,   841, "mm" ],
        a2:        [ 420,   594, "mm" ],
        a3:        [ 297,   420, "mm" ],
        a4:        [ 210,   297, "mm" ],
        a5:        [ 148,   210, "mm" ],
        a6:        [ 105,   148, "mm" ],
        a7:        [ 740,   105, "mm" ],
        a8:        [ 520,    74, "mm" ],
        a9:        [ 370,    52, "mm" ],
        a10:       [ 260,    37, "mm" ],

        b0:        [ 1000, 1414, "mm" ],
        b1:        [ 707,  1000, "mm" ],
        b2:        [ 500,   707, "mm" ],
        b3:        [ 353,   500, "mm" ],
        b4:        [ 250,   353, "mm" ],
        b5:        [ 176,   250, "mm" ],
        b6:        [ 125,   176, "mm" ],
        b7:        [ 88,    125, "mm" ],
        b8:        [ 62,     88, "mm" ],
        b9:        [ 44,     62, "mm" ],
        b10:       [ 31,     44, "mm" ],

        c0:        [ 917,  1297, "mm" ],
        c1:        [ 648,   917, "mm" ],
        c2:        [ 458,   648, "mm" ],
        c3:        [ 324,   458, "mm" ],
        c4:        [ 229,   324, "mm" ],
        c5:        [ 162,   229, "mm" ],
        c6:        [ 114,   162, "mm" ],
        c7:        [ 81,    114, "mm" ],
        c8:        [ 57,     81, "mm" ],
        c9:        [ 40,     57, "mm" ],
        c10:       [ 28,     40, "mm" ],

        business:  [ 85,     55, "mm" ],
        large:     [ 130,   210, "mm" ],
        passport:  [ 88,    125, "mm" ],
        pocket:    [ 90,    140, "mm" ],
        travelers: [ 110,   210, "mm" ],
        us:        [ 216,   279, "mm" ],
        xlarge:    [ 190,   250, "mm" ],

        icon16:    [ 16,     16, "px" ],
        icon32:    [ 32,     32, "px" ],
        icon64:    [ 64,     64, "px" ],
        icon128:   [ 128,   128, "px" ],
        icon256:   [ 256,   256, "px" ],
        icon512:   [ 512,   512, "px" ],
      }.each { |name, (width, height, unit)| define(name, width:, height:, unit:) }

      class << self
        alias_method :default, :a4
      end
    end
  end
end
