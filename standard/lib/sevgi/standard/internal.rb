# frozen_string_literal: true

module Sevgi
  module Standard
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
          end
        end
      end
    end

    private_constant :List
  end
end
