# frozen_string_literal: true

# Some parts are adapted from https://github.com/DannyBen/victor (lib/victor/attributes.rb)

module Sevgi
  module Graphics
    # Prefix for supported non-rendering element metadata.
    # Names beginning with this prefix remain available through the attribute store but are omitted from SVG output.
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

      # Owned mutable snapshots for values entering an attribute store.
      # @api private
      module Snapshot
        class << self
          def capture(value, normalize_keys: false, seen: {}.compare_by_identity)
            case value
            when ::Hash
              nested(value, seen) { capture_hash(value, normalize_keys:, seen:) }
            when ::Array
              nested(value, seen) { value.map { capture(it, seen:) } }
            else
              capture_value(value)
            end
          end

          private

          def capture_hash(value, normalize_keys:, seen:)
            identities = {}
            value.each_with_object({}) do |(key, item), captured|
              key = normalize_keys ? normalize_key(key) : capture(key, seen:)
              identity = normalize_keys ? key : XML.snapshot(key, context: "XML attribute value")
              if captured.key?(key) || identities.key?(identity)
                ArgumentError.("Attribute keys collide after normalization or stringification")
              end

              identities[identity] = true
              captured[key] = capture(item, seen:)
            end
          end

          def capture_value(value)
            text = XML.text(value, context: "XML attribute value")
            case value
            when ::Numeric, ::Symbol, ::NilClass, ::TrueClass, ::FalseClass
              value
            else
              text
            end
          end

          def nested(value, seen)
            ArgumentError.("Cyclic XML attribute value is not supported") if seen.key?(value)

            seen[value] = true
            yield
          ensure
            seen.delete(value)
          end

          def normalize_key(key)
            normalized = key.to_sym if key.respond_to?(:to_sym)
            return normalized if normalized.is_a?(::Symbol)

            ArgumentError.("Attribute Hash keys must normalize to Symbols")
          rescue Sevgi::ArgumentError
            raise
          rescue ::StandardError => e
            ArgumentError.("Attribute Hash key cannot be normalized: #{e.class}: #{e.message}")
          end
        end
      end

      private_constant :Snapshot

      # Captures a caller-independent attribute value.
      # @param value [Object] value to capture
      # @param normalize_keys [Boolean] normalize direct Hash keys to Symbols
      # @return [Object] owned mutable snapshot
      # @raise [Sevgi::ArgumentError] when value is invalid, cyclic, collides, or cannot be converted
      # @api private
      def self.capture(value, normalize_keys: false) = Snapshot.capture(value, normalize_keys:)

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

      # Mutable SVG attribute and non-rendering metadata store with Sevgi update syntax.
      #
      # Names beginning with {ATTRIBUTE_INTERNAL_PREFIX} can be read, assigned, deleted, and copied like ordinary
      # attributes. They appear in {#to_h}, but {#list}, {#export}, and rendered XML omit them.
      #
      # @example Attach non-rendering source metadata
      #   attributes = Sevgi::Graphics::Attributes.new(id: "copy", "-source": "original")
      #   attributes[:"-source"] # => "original"
      #   attributes.to_h        # => { id: "copy", :"-source" => "original" }
      #   attributes.export      # => { id: "copy" }
      class Store
        # Creates an attribute store from recursively owned snapshots. Mutable non-container leaves are stringified
        # once; later caller mutation cannot change the store.
        # @param attributes [Hash] initial attributes
        # @return [void]
        # @raise [Sevgi::ArgumentError] when input is not a Hash or a name/value is invalid, cyclic, colliding, or cannot
        #   be converted
        def initialize(attributes = {})
          @store = {}

          import(attributes)
        end

        # Atomically imports recursively owned attribute snapshots.
        # @param attributes [Hash] attributes to merge
        # @return [Hash] internal store
        # @raise [Sevgi::ArgumentError] when input is not a Hash or a name/value is invalid, cyclic, colliding, or cannot
        #   be converted
        def import(attributes)
          ArgumentError.("Attributes must be imported from a Hash") unless attributes.is_a?(::Hash)

          hash = attributes.each_with_object({}) do |(key, value), captured|
            next if value.nil?

            id = Attribute.id(key)
            ArgumentError.("Attribute names collide after normalization: #{id}") if captured.key?(id)

            captured[id] = Attribute.capture(value, normalize_keys: value.is_a?(::Hash))
          end

          @store.merge!(hash)
        end

        # Returns a live stored attribute value. Mutating a returned container intentionally mutates this store; rendering
        # revalidates the resulting value.
        # @param key [String, Symbol] attribute key
        # @return [Object, nil]
        # @raise [Sevgi::ArgumentError] when key is not a valid XML attribute name
        def [](key)
          @store[Attribute.id(key)]
        end

        # Assigns a recursively owned attribute snapshot. Mutable non-container leaves are stringified once.
        # @param key [String, Symbol] attribute key
        # @param value [Object, nil] attribute value; nil is ignored
        # @return [Object, nil] stored snapshot or nil
        # @raise [Sevgi::ArgumentError] when update syntax receives incompatible values
        # @raise [Sevgi::ArgumentError] when update syntax receives an unsupported value type
        # @raise [Sevgi::ArgumentError] when a name/value is invalid, cyclic, colliding, or cannot be converted
        def []=(key, value)
          return if value.nil?

          id = Attribute.id(key)
          value = Attribute.capture(value, normalize_keys: value.is_a?(::Hash))
          @store[id] = @store.key?(id) && Attribute.updateable?(key) ? update(id, value) : value
        end

        # Deletes an attribute by normalized key.
        # @param key [String, Symbol] attribute key
        # @return [Object, nil] deleted value
        # @raise [Sevgi::ArgumentError] when key is not a valid XML attribute name
        def delete(key)
          @store.delete(Attribute.id(key))
        end

        # Returns rendering attributes, excluding non-rendering metadata. Nested values remain live store values.
        # @return [Hash] shallow attribute view
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

        # Copies the attribute store with recursively independent values.
        # @param original [Sevgi::Graphics::Attributes] store to copy
        # @return [void]
        # @raise [Sevgi::ArgumentError] when live stored values became cyclic or invalid
        def initialize_copy(original)
          @store = {}
          original.store.each { |key, value| @store[key] = Attribute.capture(value) }

          super
        end

        # Returns rendering attribute names, excluding non-rendering metadata.
        # @return [Array<Symbol>]
        def list
          export.keys
        end

        # Returns the live attribute and metadata Hash. Mutating it intentionally mutates this store; rendering
        # revalidates rendering names and all values.
        # @return [Hash] live internal store
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

        private_constant :UPDATER

        def to_xml(id, value)
          name = XML.name(id, context: "XML attribute name")
          "#{name}=#{Attribute.xml_text(value).encode(xml: :attr)}"
        end
      end
    end

    # Public alias for the SVG attribute store.
    Attributes = Attribute::Store
    private_constant :Attribute
  end
end
