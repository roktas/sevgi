# frozen_string_literal: true

# Some parts are adapted from https://github.com/DannyBen/victor (lib/victor/attributes.rb)

module Sevgi
  module Graphics
    # Prefix for attributes considered internal and not to be exported (e.g., to XML).
    ATTRIBUTE_INTERNAL_PREFIX = "-"
    # Suffix for attribute keys that should trigger an update operation rather than overwrite.
    ATTRIBUTE_UPDATE_SUFFIX   = "+"

    # The Attribute module provides utilities for managing element attributes,
    # including identifying internal or updateable attributes and a Store class
    # for holding and manipulating attributes.
    module Attribute
      # The Ident module provides helper methods to determine the nature of an attribute key,
      # such as whether it's internal, its canonical ID, or if it's marked for update.
      module Ident
        # Checks if a given attribute key is marked as internal.
        # Internal attributes typically start with {ATTRIBUTE_INTERNAL_PREFIX}.
        # Results are memoized.
        #
        # @param given [String, Symbol] the attribute key to check.
        # @return [Boolean] true if the key is internal, false otherwise.
        def internal?(given)
          (@internal ||= {})[given] ||= given.to_s.start_with?(ATTRIBUTE_INTERNAL_PREFIX)
        end

        # Derives a canonical ID from a given attribute key.
        # If the key is updateable (ends with {ATTRIBUTE_UPDATE_SUFFIX}), the suffix is removed.
        # The result is always a Symbol. Results are memoized.
        #
        # @param given [String, Symbol] the attribute key.
        # @return [Symbol] the canonical symbol ID for the attribute.
        def id(given)
          (@id ||= {})[given] ||= (updateable?(given) ? given.to_s.delete_suffix(ATTRIBUTE_UPDATE_SUFFIX) : given).to_sym
        end

        # Checks if a given attribute key is marked as updateable.
        # Updateable attributes end with {ATTRIBUTE_UPDATE_SUFFIX}.
        # Results are memoized.
        #
        # @param given [String, Symbol] the attribute key to check.
        # @return [Boolean] true if the key is updateable, false otherwise.
        def updateable?(given)
          (@updateable ||= {})[given] ||= given.to_s.end_with?(ATTRIBUTE_UPDATE_SUFFIX)
        end
      end

      extend Ident # Make Ident methods available on the Attribute module itself.

      # The Store class is responsible for managing a collection of attributes.
      # It handles importing, accessing, setting (with update logic), deleting,
      # and exporting attributes, including conversion to XML-compatible lines.
      class Store
        # Initializes a new attribute store.
        #
        # @param attributes [Hash] an initial hash of attributes to populate the store.
        #   Keys are converted to symbols. Hash values are also processed if they are hashes.
        def initialize(attributes = {})
          @store = {}

          import(attributes)
        end

        # Imports a hash of attributes into the store.
        # Existing attributes with the same key will be merged/overwritten based on standard hash merge.
        # Keys are converted to symbols. Nested hashes also have their keys converted.
        #
        # @param attributes [Hash] the attributes to import.
        # @return [void]
        def import(attributes)
          hash = attributes.compact.to_a.map do |key, value|
            [ key.to_sym, value.is_a?(::Hash) ? value.transform_keys!(&:to_sym) : value ]
          end.to_h

          @store.merge!(hash)
        end

        # Retrieves an attribute's value by its key.
        # The key is canonicalized using {Attribute.id}.
        #
        # @param key [String, Symbol] the key of the attribute to retrieve.
        # @return [Object, nil] the value of the attribute, or nil if not found.
        def [](key)
          @store[Attribute.id(key)]
        end

        # Sets an attribute's value.
        # If the value is nil, the operation is a no-op.
        # If the key is marked as updateable (ends with {ATTRIBUTE_UPDATE_SUFFIX})
        # and an existing value exists, an update operation is performed.
        # Otherwise, the value is overwritten.
        #
        # @param key [String, Symbol] the key of the attribute to set.
        # @param value [Object] the value to set.
        # @return [void]
        def []=(key, value)
          return if value.nil?

          @store[id = Attribute.id(key)] = @store.key?(id) && Attribute.updateable?(key) ? update(id, value) : value
        end

        # Deletes an attribute from the store by its key.
        # The key is canonicalized using {Attribute.id}.
        #
        # @param key [String, Symbol] the key of the attribute to delete.
        # @return [Object, nil] the value of the deleted attribute, or nil if not found.
        def delete(key)
          @store.delete(Attribute.id(key))
        end

        # Exports non-internal attributes as a hash.
        # If an `:id` attribute exists, it is placed first in the resulting hash for aesthetic reasons.
        #
        # @return [Hash] a hash of exportable attributes.
        def export
          hash = @store.reject { |id, _| Attribute.internal?(id) }
          return hash unless hash.key?(:id)

          # A small aesthetic touch: always keep the id attribute first
          { id: hash.delete(:id), **hash }
        end

        # Checks if an attribute exists in the store by its key.
        # The key is canonicalized using {Attribute.id}.
        #
        # @param key [String, Symbol] the key to check.
        # @return [Boolean] true if the attribute exists, false otherwise.
        def has?(key)
          @store.key?(Attribute.id(key))
        end

        # Initializes a copy of this store, performing a deep dup of the internal store's values.
        #
        # @param original [Attribute::Store] the original store to copy.
        # @return [void]
        def initialize_copy(original)
          @store = {}
          original.store.each { |key, value| @store[key] = value.dup }

          super
        end

        # Returns a list of keys for all exportable attributes.
        #
        # @return [Array<Symbol>] an array of attribute keys.
        def list
          export.keys
        end

        # Returns the internal attribute store as a hash.
        # This includes internal attributes.
        #
        # @return [Hash] the raw internal hash of attributes.
        def to_h
          @store
        end

        # Converts exportable attributes to an array of XML attribute strings (e.g., `key="value"`).
        #
        # @return [Array<String>] an array of XML attribute strings.
        def to_xml_lines
          export.map { |id, value| to_xml(id, value) }
        end

        protected

          # Provides read-only access to the internal store for subclasses or internal use.
          # @return [Hash] The internal hash storing attributes.
          attr_reader :store

        private

          # Defines how different data types are updated when an attribute key
          # marked with {ATTRIBUTE_UPDATE_SUFFIX} is encountered.
          # - Strings and Symbols are concatenated with a space.
          # - Arrays are concatenated.
          # - Hashes are merged (new values overwrite old ones for the same key within the hash).
          UPDATER = {
            ::String => proc { |old_value, new_value| [ old_value, new_value ].reject(&:empty?).join(" ") },
            ::Symbol => proc { |old_value, new_value| [ old_value, new_value ].reject(&:empty?).join(" ").to_sym },
            ::Array  => proc { |old_value, new_value| old_value + new_value }, # Corrected Array update
            ::Hash   => proc { |old_value, new_value| old_value.merge(new_value.transform_keys(&:to_sym)) } # Corrected Hash update
          }.freeze

          # Updates an existing attribute value with a new value based on its type.
          # If the old value is nil, the new value is simply assigned.
          #
          # @param id [Symbol] the canonical ID of the attribute to update.
          # @param new_value [Object] the new value to incorporate.
          # @return [Object] the updated value.
          # @raise [ArgumentError] if values are incompatible or type is unsupported for update.
          def update(id, new_value)
            (old_value = @store[id]).nil? ? new_value : UPDATER[new_value.class].call(*sanitized(old_value, new_value))
          end

          # Sanitizes and validates values before an update operation.
          # Ensures that the old and new values are of the same class and that the class
          # is supported for updates by the {UPDATER} hash.
          #
          # @param old_value [Object] the existing value of the attribute.
          # @param new_value [Object] the new value to be incorporated.
          # @return [Array<Object>] an array containing the old and new values if valid.
          # @raise [ArgumentError] if values are incompatible or type is unsupported for update.
          def sanitized(old_value, new_value)
            raise ArgumentError, "Incompatible values: #{new_value.inspect} (#{new_value.class}) vs #{old_value.inspect} (#{old_value.class})" unless new_value.is_a?(old_value.class)
            raise ArgumentError, "Unsupported value type for update: #{new_value.class}" unless UPDATER.key?(new_value.class)

            [ old_value, new_value ]
          end

          private_constant :UPDATER

          # Converts a single attribute ID and value to an XML attribute string.
          # Handles Hashes and Arrays specially for formatting.
          #
          # @param id [Symbol] the ID of the attribute.
          # @param value [Object] the value of the attribute.
          # @return [String] the XML attribute string.
          def to_xml(id, value)
            case value
            when ::Hash  then %(#{id}="#{value.map { |k, v| "#{k}:#{v}" }.join("; ")}")
            when ::Array then %(#{id}="#{value.join(" ")}")
            else              %(#{id}=#{value.to_s.encode(xml: :attr)})
            end
          end
      end
    end

    # Alias for {Attribute::Store}, providing a more convenient way to refer to the class.
    Attributes = Attribute::Store
  end
end
