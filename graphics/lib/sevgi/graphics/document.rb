# frozen_string_literal: true

module Sevgi
  module Graphics
    # SVG document profile factory.
    module Document
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
      # @param preambles [Array<String>, nil] document preamble lines
      # @param attributes [Hash] default root attributes
      # @param overwrite [Boolean] true to replace an existing profile
      # @return [Class] document class
      # @raise [Sevgi::ArgumentError] when a named profile conflicts with an existing profile
      def self.define(name = Undefined, preambles: [], attributes: {}, overwrite: false)
        return Class.new(Base) { document(name, preambles:, attributes:, register: false) } if name == Undefined

        profile = Profile.new(name, attributes:, preambles:)

        if (current = Profile[name])
          unless overwrite || current.profile == profile
            ArgumentError.("Document profile already defined differently: #{name}")
          end

          return current unless overwrite
        end

        Class.new(Base) { document(name, preambles:, attributes:, overwrite:) }
      end

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

        # @return [Hash] default root attributes
        attr_reader :attributes

        # @return [Array<String>, nil] preamble lines
        attr_reader :preambles

        # Creates profile metadata.
        # @param name [Object, nil] profile name
        # @param attributes [Hash, nil] default root attributes
        # @param preambles [Array<String>, nil] preamble lines
        # @return [void]
        # @raise [Sevgi::ArgumentError] when name cannot be normalized
        def initialize(name, attributes: nil, preambles: nil)
          @name = name.nil? ? nil : self.class.normalize!(name)
          @attributes = attributes || {}
          @preambles = preambles
        end

        # Reports strict profile equality.
        # @param other [Object] object to compare
        # @return [Boolean]
        def ==(other) = self.class == other.class && deconstruct == other.deconstruct

        # Returns profile components.
        # @return [Array<(Symbol, nil), Hash, (Array<String>, nil)>]
        def deconstruct = [name, attributes, preambles]
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
