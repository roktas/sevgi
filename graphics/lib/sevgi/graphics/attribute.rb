# frozen_string_literal: true

# Some parts are adapted from https://github.com/DannyBen/victor (lib/victor/attributes.rb)

module Sevgi
  module Graphics
    # Internal store syntax; not part of the SVG DSL command surface.
    ATTRIBUTE_INTERNAL_PREFIX = "-"

    # Attribute suffix that merges new values into an existing attribute.
    ATTRIBUTE_UPDATE_SUFFIX = "+"

    # Attribute name normalization helpers.
    # @api private
    module Attribute
      # Attribute identifier helpers.
      # @api private
      module Ident
        # Reports whether an attribute is internal to Sevgi rendering.
        # @param given [String, Symbol] attribute name
        # @return [Boolean]
        def internal?(given)
          (@internal ||= {})[given] ||= key(given).start_with?(ATTRIBUTE_INTERNAL_PREFIX)
        end

        # Returns the normalized attribute id.
        # @param given [String, Symbol] attribute name
        # @return [Symbol]
        def id(given)
          (@id ||= {})[given] ||= begin
            name = updateable?(given) ? key(given).delete_suffix(ATTRIBUTE_UPDATE_SUFFIX) : key(given)
            XML.name(name, context: "XML attribute name") unless internal?(given)
            name.to_sym
          end
        end

        # Reports whether an attribute uses merge/update syntax.
        # @param given [String, Symbol] attribute name
        # @return [Boolean]
        def updateable?(given)
          (@updateable ||= {})[given] ||= key(given).end_with?(ATTRIBUTE_UPDATE_SUFFIX)
        end

        private

        def key(given)
          return given.to_s if given.is_a?(::String) || given.is_a?(::Symbol)

          ArgumentError.("XML attribute name must be a String or Symbol")
        end
      end

      extend Ident

      # Returns the text form used for an XML attribute value before escaping.
      # @param value [Object] attribute value
      # @return [String]
      # @raise [Sevgi::ArgumentError] when value is invalid, cyclic, or cannot be stringified as XML
      # @api private
      def self.xml_text(value)
        value = XML.snapshot(value, context: "XML attribute value")
        text = case value
        when ::Hash
          value.map { |key, attr_value| "#{key}:#{attr_value}" }.join("; ")
        when ::Array
          value.join(" ")
        else
          value.to_s
        end

        XML.text(text, context: "XML attribute value")
      end

      # Validates a nested XML attribute value.
      # @param value [Object] value to validate
      # @return [Object] original value
      # @raise [Sevgi::ArgumentError] when value is invalid, cyclic, or cannot be stringified as XML
      # @api private
      def self.validate(value) = XML.validate(value, context: "XML attribute value")

      # Mutable SVG attribute store with Sevgi update syntax.
      class Store
        # Creates an attribute store.
        # @param attributes [Hash] initial attributes
        # @return [void]
        # @raise [Sevgi::ArgumentError] when a name or value is not valid XML, is cyclic, or cannot be stringified
        def initialize(attributes = {})
          @store = {}

          import(attributes)
        end

        # Imports attributes into the store.
        # @param attributes [Hash] attributes to merge
        # @return [Hash] internal store
        # @raise [Sevgi::ArgumentError] when a name or value is not valid XML, is cyclic, or cannot be stringified
        def import(attributes)
          hash = attributes
            .compact
            .to_a
            .to_h do |key, value|
              id = Attribute.id(key)
              Attribute.validate(value)
              [id, import_value(value)]
            end

          @store.merge!(hash)
        end

        # Returns an attribute by normalized key.
        # @param key [String, Symbol] attribute key
        # @return [Object, nil]
        # @raise [Sevgi::ArgumentError] when key is not a valid XML attribute name
        def [](key)
          @store[Attribute.id(key)]
        end

        # Assigns an attribute value.
        # @param key [String, Symbol] attribute key
        # @param value [Object, nil] attribute value; nil is ignored
        # @return [Object, nil] assigned value or nil
        # @raise [Sevgi::ArgumentError] when update syntax receives incompatible values
        # @raise [Sevgi::ArgumentError] when update syntax receives an unsupported value type
        # @raise [Sevgi::ArgumentError] when a name or value is not valid XML, is cyclic, or cannot be stringified
        def []=(key, value)
          return if value.nil?

          id = Attribute.id(key)
          Attribute.validate(value)
          @store[id] = @store.key?(id) && Attribute.updateable?(key) ? update(id, value) : value
        end

        # Deletes an attribute by normalized key.
        # @param key [String, Symbol] attribute key
        # @return [Object, nil] deleted value
        # @raise [Sevgi::ArgumentError] when key is not a valid XML attribute name
        def delete(key)
          @store.delete(Attribute.id(key))
        end

        # Returns public attributes ready for rendering.
        # @return [Hash]
        def export
          hash = @store.reject { |id, _| Attribute.internal?(id) }
          return hash unless hash.key?(:id)

          # A small aesthetic touch: always keep the id attribute first
          {id: hash.delete(:id), **hash}
        end

        # Reports whether an attribute exists.
        # @param key [String, Symbol] attribute key
        # @return [Boolean]
        # @raise [Sevgi::ArgumentError] when key is not a valid XML attribute name
        def has?(key)
          @store.key?(Attribute.id(key))
        end

        # Copies the attribute store.
        # @param original [Sevgi::Graphics::Attribute::Store] store to copy
        # @return [void]
        def initialize_copy(original)
          @store = {}
          original.store.each { |key, value| @store[key] = copy_value(value) }

          super
        end

        # Returns public attribute names.
        # @return [Array<Symbol>]
        def list
          export.keys
        end

        # Returns the internal attribute hash.
        # @return [Hash]
        def to_h
          @store
        end

        # Returns rendered XML attribute lines.
        # @return [Array<String>]
        # @raise [Sevgi::ArgumentError] when stored names or values are invalid, cyclic, or cannot be stringified
        def to_xml_lines
          export.map { |id, value| to_xml(id, value) }
        end

        protected

        attr_reader :store

        private

        # Returns a caller-owned value copy for import.
        # @param value [Object] attribute value
        # @return [Object] imported value
        def import_value(value)
          case value
          when ::Hash
            value.transform_keys(&:to_sym)
          when ::Array
            value.dup
          else
            value
          end
        end

        UPDATER = {
          ::String => proc { |old_value, new_value| [old_value, new_value].reject(&:empty?).join(" ") },
          ::Symbol => proc { |old_value, new_value| [old_value, new_value].reject(&:empty?).join(" ").to_sym },
          ::Array => proc { |old_value, new_value| [old_value, new_value] },
          ::Hash => proc { |old_value, new_value| old_value.merge(new_value.transform_keys(&:to_sym)) }
        }.freeze

        def update(id, new_value)
          (old_value = @store[id]).nil? ? new_value : UPDATER[new_value.class].call(*sanitized(old_value, new_value))
        end

        def sanitized(old_value, new_value)
          ArgumentError.("Incompatible values: #{new_value} vs #{old_value}") unless new_value.is_a?(old_value.class)
          ArgumentError.("Unsupported value for update: #{new_value}") unless UPDATER.key?(new_value.class)

          [old_value, new_value]
        end

        def copy_value(value, seen = {}.compare_by_identity)
          return value.dup if value.is_a?(::String)
          return value unless value.is_a?(::Hash) || value.is_a?(::Array)

          copy_nested(value, seen) do
            if value.is_a?(::Hash)
              value.to_h { |key, nested| [copy_value(key, seen), copy_value(nested, seen)] }
            else
              value.map { copy_value(it, seen) }
            end
          end
        end

        def copy_nested(value, seen)
          ArgumentError.("Cannot duplicate cyclic attribute payload") if seen.key?(value)

          seen[value] = true
          yield
        ensure
          seen.delete(value)
        end

        private_constant :UPDATER

        def to_xml(id, value)
          name = XML.name(id, context: "XML attribute name")
          "#{name}=#{Attribute.xml_text(value).encode(xml: :attr)}"
        end
      end
    end

    # Public alias for the SVG attribute store.
    Attributes = Attribute::Store
  end
end
