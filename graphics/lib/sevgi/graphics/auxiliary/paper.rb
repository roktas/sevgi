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
          unit: self.class.send(:symbol!, :unit, unit),
          name: self.class.send(:symbol!, :name, name)
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
        name = symbol(name)
        name ? @mutex.synchronize { profiles.key?(name) } : false
      end

      # Defines a named paper profile after complete validation. Registration is process-global and thread-atomic.
      # Existing profiles are replaced by default; with `overwrite: false`, identical definitions return the canonical
      # profile and conflicting definitions raise. Names that are not Ruby call syntax remain accessible through
      # `public_send`.
      # @param name [Symbol, String] profile name
      # @param overwrite [Boolean] true to replace an existing profile
      # @param spec [Hash] paper dimensions and unit
      # @option spec [Numeric] :width paper width
      # @option spec [Numeric] :height paper height
      # @option spec [Symbol, String] :unit SVG unit
      # @return [Sevgi::Graphics::Paper]
      # @raise [Sevgi::ArgumentError] when the name, dimensions, unit, overwrite flag, or options are reserved or invalid,
      #   or a non-bang definition conflicts with the registered profile
      def self.define(name, overwrite: true, **spec)
        name = symbol!(:name, name)
        ArgumentError.("Paper name is reserved: #{name}") if reserved?(name)
        overwrite = overwrite!(overwrite)
        profile = new(name:, **spec)

        store(name, profile, overwrite:)
      end

      def self.accessor(name)
        return if @accessors.key?(name)

        define_singleton_method(name) { @mutex.synchronize { profiles.fetch(name) } }
        @accessors[name] = true
      end

      def self.store(name, profile, overwrite:)
        @mutex.synchronize do
          if !overwrite && (current = profiles[name])
            ArgumentError.("Paper already defined differently: #{name}") unless current == profile

            next current
          end

          accessor(name)
          profiles[name] = profile
        end
      end

      def self.reserved?(name) = @reserved.include?(name)

      def self.profiles = @profiles

      def self.dimension!(field, value)
        Scalar.finite(value, context: "paper", field:, positive: true)
      end

      def self.options!(options)
        return if options.empty?

        ArgumentError.("Unknown paper options: #{options.keys.join(", ")}")
      end

      def self.overwrite!(value)
        return value if [true, false].include?(value)

        ArgumentError.("Paper overwrite must be true or false")
      end

      def self.symbol(value)
        normalized = value.to_sym if value.respond_to?(:to_sym)
        normalized if normalized.is_a?(::Symbol)
      rescue ::StandardError
        nil
      end

      def self.symbol!(field, value)
        symbol(value) || ArgumentError.("Invalid paper #{field}")
      end

      @reserved = methods.map(&:to_sym).freeze

      private_class_method(
        :accessor,
        :dimension!,
        :options!,
        :overwrite!,
        :profiles,
        :reserved?,
        :store,
        :symbol,
        :symbol!
      )

      Papers.each { |name, (width, height, unit)| define(name, width:, height:, unit:) }

      # Returns the default paper profile.
      # @return [Sevgi::Graphics::Paper]
      def self.default
        @mutex.synchronize { profiles.fetch(:default) }
      end

      @accessors[:default] = true
      profiles[:default] = profiles.fetch(:a4)
    end
  end
end
