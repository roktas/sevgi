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

      # Immutable document profile metadata.
      # @api private
      class Profile
        @available = {}

        class << self
          # @return [Hash<Symbol, Class>] registered profile classes
          attr_reader :available
        end

        # Returns a profile class by name.
        # @param name [Object] profile name
        # @return [Class, nil]
        def self.[](name) = (name = normalize(name)) && available[name]

        # Registers a profile class.
        # @param name [Object] profile name
        # @param klass [Class] document class
        # @param overwrite [Boolean] true to replace an existing profile
        # @return [Class] registered class
        # @raise [Sevgi::ArgumentError] when name is invalid or conflicts with an existing profile
        def self.register(name, klass, overwrite: false)
          name = normalize!(name)

          if (current = available[name])
            unless overwrite || current.profile == klass.profile
              ArgumentError.("Document profile already defined differently: #{name}")
            end

            return current unless overwrite
          end

          available[name] = klass
        end

        # Normalizes a profile name.
        # @param name [Object] profile name
        # @return [Symbol, nil]
        def self.normalize(name) = name.respond_to?(:to_sym) ? name.to_sym : nil

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

      private_constant :Profile

      # Class-level DSL used while defining document classes.
      # @api private
      module DSL
        # @return [Sevgi::Graphics::Document::Profile] document profile metadata
        attr_reader :profile

        # Sets document profile metadata on a class.
        # @param name [Object] profile name
        # @param attributes [Hash] default root attributes
        # @param preambles [Array<String>, nil] preamble lines
        # @param register [Boolean] true to register the profile globally
        # @param overwrite [Boolean] true to replace an existing profile
        # @return [Sevgi::Graphics::Document::Profile]
        # @raise [Sevgi::ArgumentError] when registration fails
        def document(name, attributes: {}, preambles: nil, register: true, overwrite: false)
          @profile = Profile.new(register ? name : nil, attributes:, preambles:)
          Profile.register(name, self, overwrite:) if register
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
        # @return [Hash]
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
