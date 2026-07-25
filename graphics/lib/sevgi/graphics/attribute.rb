# frozen_string_literal: true

# Some parts are adapted from https://github.com/DannyBen/victor (lib/victor/attributes.rb)

module Sevgi
  module Graphics
    # Mutable facade for SVG attributes and non-rendering element metadata.
    class Attributes
      # Prefix marking supported non-rendering metadata names. Prefixed entries remain available through the facade but
      # are omitted from SVG output.
      META_PREFIX = "-"

      # Suffix requesting an update of an existing value. String and Symbol values are space-joined, Arrays are
      # concatenated, and Hashes are merged. When the attribute is absent, assignment uses normal replacement behavior.
      UPDATE_SUFFIX = "+"
    end

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
          (@internal ||= {})[given] ||= key(given).start_with?(Attributes::META_PREFIX)
        end

        # Returns the normalized attribute id.
        # @param given [String, Symbol] attribute name
        # @return [Symbol]
        def id(given)
          (@id ||= {})[given] ||= begin
            name = updateable?(given) ? key(given).delete_suffix(Attributes::UPDATE_SUFFIX) : key(given)
            XML.name(name, context: "XML attribute name") unless internal?(given)
            name.to_sym
          end
        end

        # Reports whether an attribute uses merge/update syntax.
        # @param given [String, Symbol] attribute name
        # @return [Boolean]
        def updateable?(given)
          (@updateable ||= {})[given] ||= key(given).end_with?(Attributes::UPDATE_SUFFIX)
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

      # Returns normalized owned attributes with defaults for absent names.
      # @param attributes [Hash] source attributes
      # @param defaults [Hash] values inserted only when their normalized names are absent
      # @return [Hash{Symbol => Object}] normalized owned attributes
      # @raise [Sevgi::ArgumentError] when input contains an invalid, colliding, or unsupported attribute
      # @api private
      def self.defaults(attributes, **defaults)
        attributes = Attributes.new(attributes)
        defaults.each { |name, value| attributes[name] = value unless attributes.has?(name) }
        attributes.to_h
      end

      # Returns normalized owned attributes.
      # @param attributes [Hash] source attributes
      # @return [Hash{Symbol => Object}] normalized owned attributes
      # @raise [Sevgi::ArgumentError] when input contains an invalid, colliding, or unsupported attribute
      # @api private
      def self.normalize(attributes) = Attributes.new(attributes).to_h

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

      # Mutable backing store for SVG attributes.
      # @api private
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
          updated = @store.dup
          entries(attributes).each { |entry| assign(updated, *entry) }

          @store.replace(updated)
        end

        # Returns a stored attribute value for the public facade.
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
          @store[id] = @store.key?(id) && Attribute.updateable?(key) ? update(@store[id], value) : value
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

          # Keep id first for stable, readable SVG output.
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

        # Returns the internal attribute and metadata Hash.
        # @return [Hash] backing store
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
          ::Array => proc { |old_value, new_value| old_value + new_value },
          ::Hash => proc { |old_value, new_value| old_value.merge(new_value) }
        }.freeze

        def assign(store, key, id, value)
          store[id] = store.key?(id) && Attribute.updateable?(key) ? update(store[id], value) : value
        end

        def entries(attributes)
          ArgumentError.("Attributes must be imported from a Hash") unless attributes.is_a?(::Hash)

          identities = {}
          attributes.filter_map do |key, value|
            next if value.nil?

            id = Attribute.id(key)
            ArgumentError.("Attribute names collide after normalization: #{id}") if identities.key?(id)

            identities[id] = true
            value = Attribute.capture(value, normalize_keys: value.is_a?(::Hash))
            [key, id, value]
          end
        end

        def update(old_value, new_value)
          UPDATER[new_value.class].call(*sanitized(old_value, new_value))
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

    # Names beginning with {META_PREFIX} can be read, assigned, deleted, merged, and copied like ordinary
    # attributes. They appear in {#to_h}, but public SVG attribute enumeration and rendered XML omit them. All values
    # entering or leaving this facade are recursively owned snapshots. Appending {UPDATE_SUFFIX} to a name requests a
    # same-family update: Strings and Symbols are space-joined, Arrays are concatenated, and Hashes are merged. An update
    # to an absent name behaves as replacement, and nil assignments are ignored.
    #
    # @example Inspect and update element attributes
    #   element = Sevgi::Graphics.SVG { rect id: "copy", "-source": "original" }.children.first
    #   element.attributes[:"-source"] # => "original"
    #   element.attributes.merge!(fill: "red")
    #   element.attributes.to_h # => { id: "copy", :"-source" => "original", fill: "red" }
    class Attributes
      # Creates an attribute facade from recursively owned snapshots.
      # @param attributes [Hash] initial attributes and non-rendering metadata
      # @return [void]
      # @raise [Sevgi::ArgumentError] when input is not a Hash or contains an invalid name or value
      def initialize(attributes = {})
        @store = Attribute::Store.new(attributes)
      end

      # Returns an owned snapshot of an attribute value.
      # @param key [String, Symbol] attribute key
      # @return [Object, nil] recursively owned value or nil when absent
      # @raise [Sevgi::ArgumentError] when key is not a valid attribute name
      def [](key) = snapshot(@store[key])

      # Assigns or updates a recursively owned attribute value.
      # @param key [String, Symbol] attribute key, optionally ending in {UPDATE_SUFFIX}
      # @param value [Object, nil] attribute value; nil is ignored
      # @return [Object, nil] recursively owned resulting value or nil when absent
      # @raise [Sevgi::ArgumentError] when the name or value is invalid, or an existing update uses incompatible or
      #   unsupported value families
      def []=(key, value)
        @store[key] = value
        snapshot(@store[key])
      end

      # Deletes an attribute and returns an owned snapshot of its value.
      # @param key [String, Symbol] attribute key
      # @return [Object, nil] deleted value or nil when absent
      # @raise [Sevgi::ArgumentError] when key is not a valid attribute name
      def delete(key) = snapshot(@store.delete(key))

      # Reports whether an attribute exists.
      # @param key [String, Symbol] attribute key
      # @return [Boolean]
      # @raise [Sevgi::ArgumentError] when key is not a valid attribute name
      def has?(key) = @store.has?(key)

      # Copies the facade with recursively independent values.
      # @param original [Sevgi::Graphics::Attributes] facade to copy
      # @return [void]
      # @raise [Sevgi::ArgumentError] when stored values became invalid
      # @api private
      def initialize_copy(original)
        super
        @store = original.store.dup
      end

      private :initialize_copy

      # Returns rendering attribute names, excluding non-rendering metadata.
      # @return [Array<Symbol>] frozen name snapshot
      def keys = @store.list.freeze

      # Atomically assigns or updates recursively owned attributes.
      # @param attributes [Hash] attributes and non-rendering metadata; names may end in {UPDATE_SUFFIX}
      # @return [Sevgi::Graphics::Attributes] self
      # @raise [Sevgi::ArgumentError] when input is not a Hash, names collide, a name or value is invalid, or an existing
      #   update uses incompatible or unsupported value families
      def merge!(attributes)
        @store.import(attributes)
        self
      end

      # Returns a recursively owned Hash snapshot including non-rendering metadata.
      # @return [Hash{Symbol => Object}] owned attribute and metadata snapshot
      def to_h = snapshot(@store.to_h)

      private

      def snapshot(value) = Attribute.capture(value)

      def xml_lines = @store.to_xml_lines

      protected

      attr_reader :store
    end

    private_constant :Attribute
  end
end
