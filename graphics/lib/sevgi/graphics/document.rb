# frozen_string_literal: true

module Sevgi
  module Graphics
    # SVG document profile factory.
    module Document
      # Defensive copy helper for profile metadata snapshots.
      # @api private
      module Snapshot
        # Returns a recursively independent copy of a value.
        # @param value [Object] value to copy
        # @return [Object] copied value
        def self.copy(value)
          case value
          when ::Hash
            hash(value)
          when ::Array
            value.map { copy(it) }
          else
            duplicate(value)
          end
        end

        # Returns a recursively frozen independent copy of a value.
        # @param value [Object] value to copy and freeze
        # @return [Object] frozen copied value
        def self.frozen(value)
          case value
          when ::Hash
            value.to_h { |key, item| [frozen(key), frozen(item)] }.freeze
          when ::Array
            value.map { frozen(it) }.freeze
          else
            duplicate(value).freeze
          end
        end

        def self.hash(value) = value.to_h { |key, item| [copy(key), copy(item)] }

        def self.duplicate(value)
          value.dup
        rescue ::TypeError
          value
        end

        private_class_method :duplicate, :hash
      end

      private_constant :Snapshot

      # Builds a root SVG element from a document profile.
      # @param document [Symbol, String, Class] profile name or document class
      # @param canvas [Sevgi::Graphics::Canvas, Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined, nil] canvas input
      # @yield evaluates the drawing DSL in the new root element
      # @yieldreturn [Object] ignored block result
      # @return [Sevgi::Graphics::Document::Proto] SVG root element
      # @raise [Sevgi::ArgumentError] when the document profile is unknown
      def self.call(document, canvas = Undefined, **, &block)
        klass = case document
        when ::Class
          document if document <= Proto
        else
          Profile[document]
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

      # Defines or returns a document profile class.
      # @param name [Symbol, String, Sevgi::Undefined] profile name, or Undefined for an anonymous profile
      # @param preambles [Array<String>, nil, Sevgi::Undefined] document preamble lines
      # @param attributes [Hash, Sevgi::Undefined] default root attributes
      # @param overwrite [Boolean] true to replace an existing profile
      # @return [Class] document class
      # @raise [Sevgi::ArgumentError] when a named profile conflicts with an existing profile
      def self.define(name = Undefined, preambles: Undefined, attributes: Undefined, overwrite: false)
        return anonymous(attributes:, preambles:) if name == Undefined

        return lookup(name) if preambles == Undefined && attributes == Undefined

        name = Profile.normalize!(name)

        if (current = Profile[name])
          reject_conflict(name, current, attributes:, preambles:) unless overwrite
          return current unless overwrite
        end

        attributes, preambles = defaults(attributes:, preambles:)
        Class.new(Base) { document(name, preambles:, attributes:, overwrite:) }
      end

      def self.anonymous(attributes:, preambles:)
        attributes, preambles = defaults(attributes:, preambles:)
        Class.new(Base) { document(Undefined, preambles:, attributes:, register: false) }
      end

      def self.lookup(name)
        name = Profile.normalize!(name)
        Profile[name] || ArgumentError.("Unknown document profile: #{name}")
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

      private_class_method :anonymous, :compatible?, :defaults, :lookup, :reject_conflict

      # Process-global document profile registry.
      # @api private
      module Registry
        @available = {}

        class << self
          def [](name) = @available[name]

          def available = @available.dup.freeze

          def register(name, klass, profile: nil, overwrite: false)
            name = Profile.normalize!(name)
            validate!(name, klass, profile)

            if (current = @available[name])
              unless overwrite || current.profile == profile
                ArgumentError.("Document profile already defined differently: #{name}")
              end

              return current unless overwrite
            end

            @available[name] = klass
          end

          private

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

      # Immutable, read-only document profile metadata exposed by document classes.
      # @see Sevgi::Graphics.document
      class Profile
        # Returns an immutable snapshot of registered profile classes.
        # @return [Hash<Symbol, Class>]
        def self.available = Registry.available

        # Returns a profile class by name.
        # @param name [Object] profile name
        # @return [Class, nil]
        def self.[](name) = (name = normalize(name)) && Registry[name]

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
        # @param attributes [Hash, nil] default root attributes
        # @param preambles [Array<String>, nil] preamble lines
        # @return [void]
        # @raise [Sevgi::ArgumentError] when name cannot be normalized
        def initialize(name, attributes: nil, preambles: nil)
          @name = name.nil? ? nil : self.class.normalize!(name)
          @attributes = Snapshot.frozen(attributes || {})
          @preambles = preambles.nil? ? nil : Snapshot.frozen(preambles)
        end

        # Reports strict profile equality.
        # @param other [Object] object to compare
        # @return [Boolean]
        def ==(other) = self.class == other.class && deconstruct == other.deconstruct

        # Returns default root attributes.
        # @return [Hash] mutation-isolated attribute snapshot
        def attributes = Snapshot.copy(@attributes)

        # Returns profile components.
        # @return [Array<(Symbol, nil), Hash, (Array<String>, nil)>]
        def deconstruct = [name, attributes, preambles]

        # Returns preamble lines.
        # @return [Array<String>, nil] mutation-isolated preamble snapshot
        def preambles = Snapshot.copy(@preambles)
      end

      # Class-level DSL used while defining document classes.
      # @api private
      module DSL
        # @return [Sevgi::Graphics::Document::Profile] immutable document profile metadata
        attr_reader :profile

        # Sets document profile metadata on a class.
        # @param name [Object] profile name
        # @param attributes [Hash] default root attributes
        # @param preambles [Array<String>, nil] preamble lines
        # @param register [Boolean] true to register the profile globally
        # @param overwrite [Boolean] true to replace an existing profile
        # @return [Sevgi::Graphics::Document::Profile] immutable document profile metadata
        # @raise [Sevgi::ArgumentError] when registration fails
        def document(name, attributes: {}, preambles: nil, register: true, overwrite: false)
          profile = Profile.new(register ? name : nil, attributes:, preambles:)
          Registry.register(name, self, profile:, overwrite:) if register
          @profile = profile
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
      end

      private_constant :DSL

      # Default render-time checks.
      DEFAULTS = {lint: true, validate: true}.freeze

      # Base document root element class.
      class Proto < Element
        public_class_method :new

        extend DSL

        mixture :Core
        mixture :Polyfills
        mixture :Render
        mixture :Wrappers

        # @overload call(*objects, **options)
        #   Renders the document.
        #   @param objects [Array<Object>] optional renderer arguments
        #   @param options [Hash] render options
        #   @return [String] SVG document source
        def call(*, **)
          options = DEFAULTS.merge(**)

          self.PreRender(*, **options) if respond_to?(:PreRender)
          self.Render(*, **options)
        end

        # Returns inherited root attributes for this document class.
        # @return [Hash{Symbol => Object}] inherited root attributes
        def self.attributes = self == Proto ? {} : {**superclass.attributes, **profile.attributes}

        # Returns inherited preamble lines for this document class.
        # @return [Array<String>, nil]
        def self.preambles = self == Proto ? nil : profile.preambles || superclass.preambles
      end

      require_relative "document/base"
      require_relative "document/minimal"

      require_relative "document/default"
      require_relative "document/html"
      require_relative "document/inkscape"
    end
  end
end
