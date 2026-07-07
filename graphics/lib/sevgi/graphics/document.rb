# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
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

      class Profile
        @available = {}

        class << self
          attr_reader :available
        end

        def self.[](name) = available[name]

        def self.register(name, klass) = (available[name] = klass)

        attr_reader :name, :attributes, :preambles

        def initialize(name, attributes: nil, preambles: nil)
          @name = name
          @attributes = attributes || {}
          @preambles = preambles
        end
      end

      private_constant :Profile

      module DSL
        attr_reader :profile

        def document(name, attributes: {}, preambles: nil, register: true)
          @profile = Profile.new(register ? name : nil, attributes:, preambles:).tap do
            Profile.register(name, self) if register
          end
        end

        def mixture(mixture, ns: Graphics::Mixtures)
          include(mod = ns.const_get(mixture))
          extend(mod::ClassMethods) if defined?(mod::ClassMethods)
        end
      end

      private_constant :DSL

      DEFAULTS = {lint: true, validate: true}.freeze

      class Proto < Element
        public_class_method :new

        extend DSL

        mixture :Core
        mixture :Polyfills
        mixture :Render
        mixture :Wrappers

        def call(*, **)
          options = DEFAULTS.merge(**)

          self.PreRender(*, **options) if respond_to?(:PreRender)
          self.Render(*, **options)
        end

        def self.attributes = self == Proto ? {} : {**superclass.attributes, **profile.attributes}

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
