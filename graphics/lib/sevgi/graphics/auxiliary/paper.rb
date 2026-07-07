# frozen_string_literal: true

module Sevgi
  module Graphics
    # Paper size and unit profile.
    Paper = Data.define(:width, :height, :unit, :name) do
      include Comparable

      # @!attribute [r] width
      #   @return [Float] paper width
      # @!attribute [r] height
      #   @return [Float] paper height
      # @!attribute [r] unit
      #   @return [Symbol] SVG unit
      # @!attribute [r] name
      #   @return [Symbol] profile name

      # Creates a paper profile.
      # @param width [Numeric] paper width
      # @param height [Numeric] paper height
      # @param unit [Symbol, String] SVG unit
      # @param name [Symbol, String] profile name
      # @return [void]
      # @raise [Sevgi::ArgumentError] when dimensions, unit, or profile name are invalid
      def initialize(width:, height:, unit: "mm", name: :custom)
        super(
          width: self.class.send(:dimension!, :width, width),
          height: self.class.send(:dimension!, :height, height),
          unit: self.class.send(:symbol!, :unit, unit),
          name: self.class.send(:symbol!, :name, name)
        )
      end

      # Compares papers by width, height, unit, then name.
      # @param other [Sevgi::Graphics::Paper] paper to compare
      # @return [Integer, nil]
      def <=>(other) = deconstruct <=> other.deconstruct

      # Reports strict paper equality.
      # @param other [Object] object to compare
      # @return [Boolean]
      def eql?(other) = self.class == other.class && deconstruct == other.deconstruct

      # Returns a hash compatible with strict equality.
      # @return [Integer]
      def hash = [self.class, *deconstruct].hash

      # Returns the longer side.
      # @return [Float]
      def longest = [width, height].max

      # Returns the shorter side.
      # @return [Float]
      def shortest = [width, height].min

      alias_method :==, :eql?

      @profiles = {}

      # Reports whether a named paper profile exists.
      # @param name [Object] profile name
      # @return [Boolean]
      def self.exist?(name) = name.respond_to?(:to_sym) && profiles.key?(name.to_sym)

      # Defines or replaces a named paper profile.
      # @param name [Symbol, String] profile name
      # @param spec [Hash] paper dimensions and unit
      # @option spec [Numeric] :width paper width
      # @option spec [Numeric] :height paper height
      # @option spec [Symbol, String] :unit SVG unit
      # @return [Sevgi::Graphics::Paper]
      # @raise [Sevgi::ArgumentError] when the profile name is reserved or invalid
      def self.define(name, **spec)
        name = symbol!(:name, name)

        ArgumentError.("Paper name is reserved: #{name}") if reserved?(name) && !exist?(name)

        singleton_class.remove_method(name) if singleton_class.method_defined?(name, false)
        singleton_class.attr_reader(name)
        profiles[name] = instance_variable_set("@#{name}", new(name:, **spec))
      end

      def self.reserved?(name) = @reserved.include?(name.to_sym)

      def self.profiles = @profiles

      def self.dimension!(field, value)
        Float(value)
      rescue ::ArgumentError, ::TypeError
        ArgumentError.("Invalid paper #{field}: #{value.inspect}")
      end

      def self.symbol!(field, value)
        value.to_sym
      rescue ::NoMethodError, ::TypeError
        ArgumentError.("Invalid paper #{field}: #{value.inspect}")
      end

      @reserved = methods.map(&:to_sym).freeze

      private_class_method :dimension!, :profiles, :reserved?, :symbol!

      {
        a0: [841, 1189, "mm"],
        a1: [594, 841, "mm"],
        a2: [420, 594, "mm"],
        a3: [297, 420, "mm"],
        a4: [210, 297, "mm"],
        a5: [148, 210, "mm"],
        a6: [105, 148, "mm"],
        a7: [74, 105, "mm"],
        a8: [52, 74, "mm"],
        a9: [37, 52, "mm"],
        a10: [26, 37, "mm"],

        b0: [1000, 1414, "mm"],
        b1: [707, 1000, "mm"],
        b2: [500, 707, "mm"],
        b3: [353, 500, "mm"],
        b4: [250, 353, "mm"],
        b5: [176, 250, "mm"],
        b6: [125, 176, "mm"],
        b7: [88, 125, "mm"],
        b8: [62, 88, "mm"],
        b9: [44, 62, "mm"],
        b10: [31, 44, "mm"],

        c0: [917, 1297, "mm"],
        c1: [648, 917, "mm"],
        c2: [458, 648, "mm"],
        c3: [324, 458, "mm"],
        c4: [229, 324, "mm"],
        c5: [162, 229, "mm"],
        c6: [114, 162, "mm"],
        c7: [81, 114, "mm"],
        c8: [57, 81, "mm"],
        c9: [40, 57, "mm"],
        c10: [28, 40, "mm"],

        business: [85, 55, "mm"],
        large: [130, 210, "mm"],
        passport: [88, 125, "mm"],
        pocket: [90, 140, "mm"],
        travelers: [110, 210, "mm"],
        us: [216, 279, "mm"],
        xlarge: [190, 250, "mm"],

        icon16: [16, 16, "px"],
        icon32: [32, 32, "px"],
        icon64: [64, 64, "px"],
        icon128: [128, 128, "px"],
        icon256: [256, 256, "px"],
        icon512: [512, 512, "px"]
      }.each { |name, (width, height, unit)| define(name, width:, height:, unit:) }

      class << self
        alias_method :default, :a4
      end

      profiles[:default] = profiles.fetch(:a4)
    end
  end
end
