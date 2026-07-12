# frozen_string_literal: true

module Sevgi
  module Graphics
    # SVG document profile factory.
    module Document
      # Defensive copy helper for profile metadata snapshots.
      # @api private
      module Snapshot
        class << self
          # Captures recursively immutable profile metadata. Mutable non-container values are stringified once.
          # @param value [Object] value to capture
          # @param seen [Hash] container identities on the current traversal path
          # @return [Object] immutable captured value
          # @raise [Sevgi::ArgumentError] when metadata is cyclic, has colliding keys, or cannot be stringified
          def capture(value, seen = {}.compare_by_identity)
            case value
            when ::Hash
              nested(value, seen) { capture_hash(value, seen) }.freeze
            when ::Array
              nested(value, seen) { value.map { capture(it, seen) } }.freeze
            else
              capture_value(value)
            end
          end

          # Returns a recursively caller-owned copy of captured metadata.
          # @param value [Object] captured value to copy
          # @return [Object] caller-owned copy
          def copy(value)
            case value
            when ::String
              value.dup
            when ::Hash
              value.to_h { |key, item| [copy(key), copy(item)] }
            when ::Array
              value.map { copy(it) }
            else
              value
            end
          end

          private

          def capture_hash(value, seen)
            value.each_with_object({}) do |(key, item), captured|
              key = capture(key, seen)
              ArgumentError.("Document profile metadata keys collide after stringification") if captured.key?(key)

              captured[key] = capture(item, seen)
            end
          end

          def nested(value, seen)
            ArgumentError.("Cyclic document profile metadata is not supported") if seen.key?(value)

            seen[value] = true
            yield
          ensure
            seen.delete(value)
          end

          def capture_value(value)
            case value
            when ::String
              XML.text(value, context: "Document profile metadata").freeze
            when ::Numeric, ::Symbol, ::NilClass, ::TrueClass, ::FalseClass
              XML.text(value, context: "Document profile metadata")
              value
            else
              stringify(value).freeze
            end
          end

          def stringify(value)
            XML.text(value, context: "Document profile metadata")
          end
        end
      end

      private_constant :Snapshot

      # Builds a root SVG element from a document profile.
      # @param document [Symbol, String, Class] profile name or document class
      # @param canvas [Sevgi::Graphics::Canvas, Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined, nil] canvas input
      # @yield evaluates the drawing DSL in the new root element
      # @yieldreturn [Object] ignored block result
      # @return [Sevgi::Graphics::Document::Proto] SVG root element
      # @raise [Sevgi::ArgumentError] when the document profile or root XML attributes are invalid
      # @example Extend a configured class while inheriting its profile
      #   Card = Class.new(Document::Minimal)
      #   Document.(Card) { rect(width: 10, height: 5) }
      def self.call(document, canvas = Undefined, **, &block)
        klass = case document
        when ::Class
          document if document <= Proto
        else
          fetch(document)
        end

        ArgumentError.("Unknown document profile: #{document}") unless klass

        klass.root(**klass.attributes, **canvas_attributes(canvas), **, &block)
      end

      def self.canvas_attributes(canvas)
        case canvas
        when Undefined, ::NilClass
          {}
        when Canvas
          canvas.attributes
        else
          Canvas.from_paper(canvas).attributes
        end
      end

      private_class_method :canvas_attributes

      # Returns a registered document class by profile name.
      # @param name [Symbol, String] profile name
      # @return [Class] registered subclass of {Sevgi::Graphics::Document::Proto}
      # @raise [Sevgi::ArgumentError] when name is invalid or unknown
      # @example Look up a document class and its metadata
      #   klass = Document.fetch(:minimal)
      #   Document.profile(:minimal) # => klass.profile
      def self.fetch(name)
        name = Profile.normalize!(name)
        Registry[name] || ArgumentError.("Unknown document profile: #{name}")
      end

      # Reports whether a normalizable document profile name is registered.
      # Invalid converters return false and do not change the registry.
      # @example Check a built-in profile
      #   Document.exist?(:minimal) # => true
      # @param name [Object] profile name
      # @return [Boolean]
      def self.exist?(name)
        name = Profile.normalize(name)
        name ? !Registry[name].nil? : false
      end

      # Returns registered document profile names.
      # @return [Array<Symbol>] frozen name snapshot
      def self.keys = Registry.available.keys.freeze

      # Returns immutable metadata for a registered document profile.
      # @param name [Symbol, String] profile name
      # @return [Sevgi::Graphics::Document::Profile] registered profile metadata
      # @raise [Sevgi::ArgumentError] when name is invalid or unknown
      def self.profile(name) = fetch(name).profile

      # Defines or returns a document profile class.
      # Profile metadata is captured before class or thread-atomic registry mutation. Mutable non-container attribute
      # values are stringified once during capture. Successful named definitions return the canonical class stored by
      # the registry, including when identical definitions race.
      # @param name [Symbol, String, Sevgi::Undefined] profile name, or Undefined for an anonymous profile
      # @param preambles [Array<String>, nil, Sevgi::Undefined] document preamble lines
      # @param attributes [Hash, nil, Sevgi::Undefined] default root attributes
      # @param overwrite [Boolean] true to replace an existing profile
      # @return [Class] document class
      # @raise [Sevgi::ArgumentError] when overwrite is not Boolean, a name conflicts, or metadata is invalid XML,
      #   cyclic, or cannot be stringified
      def self.define(name = Undefined, preambles: Undefined, attributes: Undefined, overwrite: false)
        overwrite!(overwrite)
        return anonymous(attributes:, preambles:) if name == Undefined

        return lookup(name) if preambles == Undefined && attributes == Undefined

        name = Profile.normalize!(name)
        current = reuse(name, attributes:, preambles:, overwrite:)
        return current if current

        attributes, preambles = defaults(attributes:, preambles:)
        Class.new(Base) { document(name, preambles:, attributes:, overwrite:) }
        Registry[name]
      end

      def self.anonymous(attributes:, preambles:)
        attributes, preambles = defaults(attributes:, preambles:)
        Class.new(Base) { document(Undefined, preambles:, attributes:, register: false) }
      end

      def self.lookup(name)
        fetch(name)
      end

      def self.defaults(attributes:, preambles:)
        [attributes == Undefined ? {} : attributes, preambles == Undefined ? nil : preambles]
      end

      def self.reject_conflict(name, current, attributes:, preambles:)
        return if compatible?(current, attributes:, preambles:)

        ArgumentError.("Document profile already defined differently: #{name}")
      end

      def self.compatible?(klass, attributes:, preambles:)
        profile = klass.profile

        (attributes == Undefined || Profile.new(nil, attributes:).attributes == profile.attributes) &&
          (preambles == Undefined || Profile.new(nil, preambles:).preambles == profile.preambles)
      end

      def self.reuse(name, attributes:, preambles:, overwrite:)
        return unless (current = Registry[name])

        reject_conflict(name, current, attributes:, preambles:) unless overwrite
        current unless overwrite
      end

      def self.overwrite!(value)
        return value if [true, false].include?(value)

        ArgumentError.("Document overwrite must be true or false")
      end

      private_class_method :anonymous, :compatible?, :defaults, :lookup, :overwrite!, :reject_conflict, :reuse

      # Process-global document profile registry.
      # @api private
      module Registry
        @available = {}
        @mutex = ::Mutex.new

        class << self
          def [](name) = @mutex.synchronize { @available[name] }

          def available = @mutex.synchronize { @available.dup.freeze }

          def register(name, klass, profile: nil, overwrite: false)
            overwrite = Document.send(:overwrite!, overwrite)
            name = Profile.normalize!(name)
            validate!(name, klass, profile)

            @mutex.synchronize { store(name, klass, profile, overwrite) }
          end

          private

          def store(name, klass, profile, overwrite)
            if (current = @available[name])
              unless overwrite || current.profile == profile
                ArgumentError.("Document profile already defined differently: #{name}")
              end

              return current unless overwrite
            end

            klass.instance_variable_set(:@profile, profile)
            @available[name] = klass
          end

          def validate!(name, klass, profile)
            unless klass.is_a?(::Class) && klass <= Proto
              ArgumentError.("Document profile class must inherit Document::Proto: #{klass}")
            end

            return if profile.is_a?(Profile) && profile.name == name

            ArgumentError.("Document profile class has invalid metadata: #{klass}")
          end
        end
      end

      private_constant :Registry

      # Immutable, read-only document profile metadata exposed by document classes. Process-global lookup and registration
      # are thread-atomic. Metadata containers and strings are captured recursively; other mutable attribute values are
      # stringified once during construction.
      # @see Sevgi::Graphics.document
      class Profile
        # Normalizes a profile name.
        # @param name [Object] profile name
        # @return [Symbol, nil]
        def self.normalize(name)
          normalized = name.to_sym if name.respond_to?(:to_sym)
          normalized if normalized.is_a?(::Symbol)
        rescue ::StandardError
          nil
        end

        # Normalizes a profile name or raises.
        # @param name [Object] profile name
        # @return [Symbol]
        # @raise [Sevgi::ArgumentError] when name cannot be normalized
        def self.normalize!(name) = normalize(name) || ArgumentError.("Invalid document profile: #{name}")

        # @return [Symbol, nil] profile name
        attr_reader :name

        # Creates profile metadata.
        # @param name [Object, nil] profile name
        # @param attributes [Hash, nil] default root attributes; nil means an empty Hash
        # @param preambles [Array<String>, nil] preamble lines
        # @return [void]
        # @raise [Sevgi::ArgumentError] when name or metadata is invalid XML, cyclic, or cannot be stringified
        def initialize(name, attributes: nil, preambles: nil)
          @name = name.nil? ? nil : self.class.normalize!(name)
          validate_attributes!(attributes)
          @attributes = Snapshot.capture(attributes || {})
          @preambles = capture_preambles(preambles)
          freeze
        end

        # Reports strict profile equality.
        # @param other [Object] object to compare
        # @return [Boolean]
        def eql?(other) = self.class == other.class && deconstruct == other.deconstruct

        # Returns a hash compatible with strict equality.
        # @return [Integer]
        def hash = [self.class, name, @attributes, @preambles].hash

        # Returns default root attributes.
        # @return [Hash] mutation-isolated attribute snapshot
        def attributes = Snapshot.copy(@attributes)

        # Returns profile components.
        # @return [Array<(Symbol, nil), Hash, (Array<String>, nil)>]
        def deconstruct = [name, attributes, preambles]

        # Returns preamble lines.
        # @return [Array<String>, nil] mutation-isolated preamble snapshot
        def preambles = Snapshot.copy(@preambles)

        alias == eql?

        private

        def validate_attributes!(attributes)
          return if attributes.nil?

          ArgumentError.("Document profile attributes must be a Hash") unless attributes.is_a?(::Hash)

          normalized = {}
          attributes.each_key do |key|
            id = normalize_attribute!(key)
            ArgumentError.("Document profile attribute names collide after normalization: #{id}") if normalized.key?(id)

            normalized[id] = true
          end
        end

        def normalize_attribute!(key)
          if key.is_a?(::String) || key.is_a?(::Symbol)
            return XML.name(key, context: "Document profile attribute name").to_sym
          end

          ArgumentError.("Document profile attribute names must be Strings or Symbols")
        end

        def capture_preambles(preambles)
          return if preambles.nil?

          unless preambles.is_a?(::Array) && preambles.all?(::String)
            ArgumentError.("Document profile preambles must be an Array of Strings")
          end

          Snapshot.capture(preambles)
        end
      end

      # Class-level DSL used while defining document classes.
      # @api private
      module DSL
        # Sets document profile metadata on a class.
        # @param name [Object] profile name
        # @param attributes [Hash, nil] default root attributes
        # @param preambles [Array<String>, nil] preamble lines
        # @param register [Boolean] true to register the profile globally
        # @param overwrite [Boolean] true to replace an existing profile
        # @return [Sevgi::Graphics::Document::Profile] immutable document profile metadata
        # @raise [Sevgi::ArgumentError] when registration fails or metadata is invalid XML, cyclic, or cannot be stringified
        def document(name, attributes: {}, preambles: nil, register: true, overwrite: false)
          overwrite = Document.send(:overwrite!, overwrite)
          profile = Profile.new(register ? name : nil, attributes:, preambles:)
          return (@profile = profile) unless register

          registered = Registry.register(name, self, profile:, overwrite:)
          @profile = profile unless registered.equal?(self)
          @profile
        end

        # Includes a graphics mixture into the document class.
        # @param mixture [Symbol, String] mixture constant name
        # @param ns [Module] namespace containing mixture modules
        # @return [Module] included mixture module
        # @raise [NameError] when the mixture does not exist
        def mixture(mixture, ns: Graphics::Mixtures)
          include(mod = ns.const_get(mixture))
          extend(mod::ClassMethods) if defined?(mod::ClassMethods)
        end

        private :document, :mixture
      end

      private_constant :DSL

      # Default render-time checks.
      # @api private
      DEFAULTS = {lint: true, validate: true}.freeze
      private_constant :DEFAULTS

      # Base document root element class.
      class Proto < Element
        extend DSL

        mixture :Core
        mixture :Polyfills
        mixture :Render
        mixture :Wrappers

        # Returns the nearest immutable profile metadata in the class hierarchy.
        # @return [Sevgi::Graphics::Document::Profile, nil] nearest profile, or nil when no ancestor is configured
        def self.profile
          return @profile if instance_variable_defined?(:@profile)

          superclass.profile if superclass.respond_to?(:profile)
        end

        # Renders this document after its optional pre-render checks.
        # @example Render a document directly with separate check and renderer options
        #   document = Sevgi::Graphics.SVG(:minimal) { rect(width: 3) }
        #   document.call(lint: false, style: :inline)
        # @param options [Hash] `lint` and `validate` check switches plus renderer options accepted by
        #   {Sevgi::Graphics::Mixtures::Render#Render}
        # @option options [Boolean] :lint (true) run document lint checks
        # @option options [Boolean] :validate (true) run SVG standard validation
        # @return [String] SVG document source
        # @raise [Sevgi::ArgumentError] when an option or XML-bound value is invalid
        # @see Sevgi::Graphics::Mixtures::Render#Render
        def call(**options)
          checks = DEFAULTS.merge(options.select { |key, _| DEFAULTS.key?(key) })
          self.PreRender(**checks) if respond_to?(:PreRender)
          render_options = options.reject { |key, _| DEFAULTS.key?(key) }
          self.Render(**render_options)
        end

        # Returns inherited root attributes for this document class.
        # @return [Hash{Symbol => Object}] inherited root attributes
        # @raise [Sevgi::ArgumentError] when a non-Proto class has no configured ancestor
        def self.attributes
          return {} if self == Proto

          ArgumentError.("Document class has no configured profile: #{self}") unless profile
          return superclass.attributes unless instance_variable_defined?(:@profile)

          {**superclass.attributes, **@profile.attributes}
        end

        # Returns inherited preamble lines for this document class.
        # @return [Array<String>, nil]
        # @raise [Sevgi::ArgumentError] when a non-Proto class has no configured ancestor
        def self.preambles
          return if self == Proto

          ArgumentError.("Document class has no configured profile: #{self}") unless profile
          return superclass.preambles unless instance_variable_defined?(:@profile)

          @profile.preambles || superclass.preambles
        end
      end

      require_relative "document/base"
      require_relative "document/minimal"

      require_relative "document/default"
      require_relative "document/html"
      require_relative "document/inkscape"
    end
  end
end
