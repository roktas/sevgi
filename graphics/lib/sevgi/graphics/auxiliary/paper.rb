# frozen_string_literal: true

module Sevgi
  module Graphics
    # Paper size and unit profile.
    # @!parse
    #   class Paper
    #     # Creates a paper profile from dimensions and optional metadata.
    #     # @param width [Numeric] paper width
    #     # @param height [Numeric] paper height
    #     # @param unit [Symbol, String] SVG unit
    #     # @param name [Symbol, String] profile name
    #     # @return [Sevgi::Graphics::Paper]
    #     # @raise [Sevgi::ArgumentError] when dimensions, unit, or name are invalid
    #     # @example Create a custom paper profile with value notation
    #     #   Sevgi::Graphics::Paper[90, 50, :mm, :card]
    #     def self.[](width, height, unit = "mm", name = :custom); end
    #   end
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

      # Creates a paper profile. Dimensions must be finite real numbers greater than zero.
      # @param width [Numeric] paper width
      # @param height [Numeric] paper height
      # @param unit [Symbol, String] SVG unit
      # @param name [Symbol, String] profile name
      # @param options [Hash] unsupported extra options
      # @return [void]
      # @raise [Sevgi::ArgumentError] when dimensions, unit, name, or options are invalid
      def initialize(width:, height:, unit: "mm", name: :custom, **options)
        self.class.send(:options!, options)
        super(
          width: self.class.send(:dimension!, :width, width),
          height: self.class.send(:dimension!, :height, height),
          unit: self.class.send(:normalize!, :unit, unit),
          name: self.class.send(:normalize!, :name, name)
        )
      end

      # Compares papers by width, height, unit, then name.
      # @param other [Sevgi::Graphics::Paper] paper to compare
      # @return [Integer, nil] comparison result, or nil for a non-Paper operand
      def <=>(other)
        deconstruct <=> other.deconstruct if other.is_a?(self.class)
      end

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
      @accessors = {}
      @mutex = ::Mutex.new

      # Reports whether a normalizable named paper profile exists. Invalid converters return false.
      # @param name [Object] profile name
      # @return [Boolean]
      def self.exist?(name)
        name = normalize(name)
        name ? @mutex.synchronize { @profiles.key?(name) } : false
      end

      # Returns a registered paper profile by name.
      # @param name [Symbol, String] profile name, including names that are not Ruby identifiers
      # @return [Sevgi::Graphics::Paper] registered profile
      # @raise [Sevgi::ArgumentError] when name is invalid or no profile is registered
      # @example Look up a non-identifier profile name
      #   Sevgi::Graphics::Paper.define("business-card", width: 90, height: 50)
      #   Sevgi::Graphics::Paper.fetch("business-card")
      def self.fetch(name)
        name = normalize!(:name, name)
        @mutex.synchronize { @profiles.fetch(name) { ArgumentError.("Unknown paper profile: #{name}") } }
      end

      # Returns registered profile names.
      # @return [Array<Symbol>] frozen name snapshot
      def self.keys = @mutex.synchronize { @profiles.keys.freeze }

      # Defines a named paper profile after complete validation. Registration is process-global and thread-atomic.
      # Identical definitions return the canonical profile and conflicting definitions raise unless replacement is
      # explicitly requested. Names that are not Ruby call syntax remain accessible through {.fetch}.
      # @param name [Symbol, String] profile name
      # @param overwrite [Boolean] true to replace an existing profile
      # @param spec [Hash] paper dimensions and unit
      # @option spec [Numeric] :width paper width
      # @option spec [Numeric] :height paper height
      # @option spec [Symbol, String] :unit SVG unit
      # @return [Sevgi::Graphics::Paper]
      # @raise [Sevgi::ArgumentError] when the name, dimensions, unit, overwrite flag, or options are reserved or invalid,
      #   or a non-bang definition conflicts with the registered profile
      # @example Define or reuse a matching profile
      #   Sevgi::Graphics::Paper.define(:card, width: 90, height: 50)
      # @example Replace a profile explicitly
      #   Sevgi::Graphics::Paper.define(:card, width: 100, height: 60, overwrite: true)
      def self.define(name, overwrite: false, **spec)
        name = normalize!(:name, name)
        ArgumentError.("Paper name is reserved: #{name}") if reserved?(name)
        overwrite = overwrite!(overwrite)
        profile = new(name:, **spec)

        register(name, profile, overwrite:)
      end

      class << self
        private

        def install(name)
          return if @accessors.key?(name)

          define_singleton_method(name) { @mutex.synchronize { @profiles.fetch(name) } }
          @accessors[name] = true
        end

        def register(name, profile, overwrite:)
          @mutex.synchronize do
            if !overwrite && (current = @profiles[name])
              ArgumentError.("Paper already defined differently: #{name}") unless current == profile

              next current
            end

            install(name)
            @profiles[name] = profile
          end
        end

        def reserved?(name) = @reserved.include?(name)

        def dimension!(field, value)
          Scalar.finite(value, context: "paper", field:, positive: true)
        end

        def options!(options)
          return if options.empty?

          ArgumentError.("Unknown paper options: #{options.keys.join(", ")}")
        end

        def overwrite!(value)
          return value if [true, false].include?(value)

          ArgumentError.("Paper overwrite must be true or false")
        end

        def normalize(value)
          normalized = value.to_sym if value.respond_to?(:to_sym)
          normalized if normalized.is_a?(::Symbol)
        rescue ::StandardError
          nil
        end

        def normalize!(field, value)
          normalize(value) || ArgumentError.("Invalid paper #{field}")
        end
      end

      @reserved = methods.map(&:to_sym).freeze

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

      # Returns the default paper profile.
      # @return [Sevgi::Graphics::Paper]
      def self.default
        @mutex.synchronize { @profiles.fetch(:default) }
      end

      @accessors[:default] = true
      @profiles[:default] = @profiles.fetch(:a4)
    end
  end
end
