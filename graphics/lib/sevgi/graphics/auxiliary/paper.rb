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

      PAPER_SIZES.each { |name, (width, height, unit)| define(name, width:, height:, unit:) }

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
