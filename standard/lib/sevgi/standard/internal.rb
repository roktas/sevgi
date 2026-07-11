# frozen_string_literal: true

module Sevgi
  module Standard
    # Normalizes public SVG standard names at API boundaries.
    # @api private
    module Name
      PATTERN = /\A[A-Za-z_][A-Za-z0-9_.-]*(?::[A-Za-z_][A-Za-z0-9_.-]*)?\z/
      private_constant :PATTERN

      # Reports whether a string is a supported SVG-style name token.
      # @param name [String] candidate name
      # @return [Boolean]
      def self.valid?(name) = !!PATTERN.match?(name)

      # Normalizes one public name to the registry symbol form.
      # @param value [String, Symbol] public name
      # @param context [String] name context for error messages
      # @return [Symbol] normalized name
      # @raise [Sevgi::ArgumentError] when value is not a String or Symbol
      # @raise [Sevgi::ArgumentError] when value is not a valid SVG-style name
      def self.normalize!(value, context:)
        case value
        when ::String, ::Symbol
          text = value.to_s
          ArgumentError.("Invalid SVG #{context} name: #{value.inspect}") unless valid?(text)

          text.to_sym
        else
          ArgumentError.("SVG #{context} name must be a String or Symbol: #{value.inspect}")
        end
      end

      # Normalizes a list of public names.
      # @param values [Array<String, Symbol>, String, Symbol, nil] public names
      # @param context [String] name context for error messages
      # @return [Array<Symbol>, nil] normalized names
      # @raise [Sevgi::ArgumentError] when any value is not a valid public name
      def self.list!(values, context:)
        return if values.nil?

        values = [values] unless values.is_a?(::Array)
        values.map { normalize!(it, context:) }
      end
    end

    private_constant :Name

    # Low-level import and lookup helper for static SVG standard data.
    # @api private
    module List
      # Looks up a data entry.
      # @param name [Symbol] data key
      # @return [Object, nil] stored data value
      def [](name) = data[name]

      # Imports new data entries without overwriting existing keys.
      # @param kwargs [Hash] entries to import
      # @return [Hash] backing data hash
      def import(**kwargs) = data.merge!(kwargs.reject { |key, _| data.key?(key) })

      # Reports whether a data entry exists.
      # @param name [Symbol] data key
      # @return [Boolean]
      def valid?(name) = data.key?(name)

      # Initializes the backing data hash on extended modules.
      # @param base [Module] module receiving list behavior
      # @return [void]
      # @api private
      def self.extended(base)
        super

        base.class_exec do
          @data = {}

          class << self
            attr_reader :data
            private :data
          end
        end
      end
    end

    private_constant :List
  end
end
