# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      def self.call(document, canvas = Undefined, **, &block)
        case canvas
        when Undefined, ::NilClass then {}
        when Canvas                then canvas.attributes
        else                            Canvas.(canvas).attributes
        end => attributes

        (klass = Profile[document]).root(**klass.attributes, **attributes, **, &block)
      end

      class Profile
        @available = {}

        class << self
          attr_reader :available
        end

        def self.[](name)              = available[name]

        def self.register(name, klass) = (available[name] = klass)

        attr_reader :name, :attributes, :preambles

        def initialize(name, attributes: nil, preambles: nil)
          @name       = name
          @attributes = attributes || {}
          @preambles  = preambles
        end
      end

      private_constant :Profile

      module DSL
        attr_reader :profile

        def document(name, attributes: {}, preambles: nil)
          @profile = Profile.new(name, attributes:, preambles:).tap do
            Profile.register(name, self)
          end
        end

        def mixture(mixture, ns: Graphics::Mixtures)
          include(mod = ns.const_get(mixture))
          extend(mod::ClassMethods) if defined?(mod::ClassMethods)
        end
      end

      private_constant :DSL

      DEFAULTS = { lint: true, validate: true }.freeze

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

        def self.attributes = self == Proto ? {} : { **superclass.attributes, **profile.attributes }

        def self.preambles  = self == Proto ? nil : profile.preambles || superclass.preambles
      end

      require_relative "document/base"
      require_relative "document/minimal"

      require_relative "document/default"
      require_relative "document/html"
      require_relative "document/inkscape"
    end
  end
end
