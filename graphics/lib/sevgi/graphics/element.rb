# frozen_string_literal: true

require "sevgi/standard"

module Sevgi
  module Graphics
    class Element
      def self.element(name, *, parent:, &block) = new(name, **Dispatch.parse(name, *), parent:, &block)

      def self.root(*, &block)                   = element(:svg, *, parent: RootParent, &block)

      def self.root?(element)                    = element.parent == RootParent

      class << self
        require "sevgi/standard"

        def valid?(name)                      = Standard.element?(name)
      rescue ::LoadError
        def valid?(...)                       = true
      end

      private_class_method :new

      RootParent = Object.new.tap { def it.inspect = "RootParent" }.freeze

      module Ident
        def id(given) = (@id ||= {})[given] ||= given.to_s.tr("_", "-").to_sym
      end

      extend Ident

      attr_reader :name, :attributes, :children, :contents, :parent

      def initialize(name, attributes: {}, contents: [], parent:, &block)
        @name       = name
        @attributes = Attributes.new(attributes)
        @children   = []
        @contents   = contents
        @parent     = parent

        parent.children << self unless self.class.root?(self)

        instance_exec(&block) if block
      end

      def method_missing(name, *, &block)
        Element.valid?(id = Element.id(name)) ? Dispatch.(self, id, *, &block) : super
      end

      def respond_to_missing?(name, include_private = false)
        Element.valid?(Element.id(name)) || super
      end

      module Dispatch
        extend self

        def call(element, name, *, &block)
          # Low-hanging fruit optimization: define missing method to avoid dispatching cost
          Element.class_exec do
            define_method(name) { |*args, &block| self.class.element(name, *args, parent: self, &block) }
          end unless Element.method_defined?(name)

          element.public_send(name, *, &block)
        end

        def parse(name, *args)
          attributes, contents = {}, []

          args.each do |arg|
            case arg
            when ::Hash   then attributes = arg
            when ::String then contents << Content.encoded(arg)
            when Content  then contents << arg
            else               ArgumentError.("Argument of element '#{name}' must be a Hash or String: #{arg}")
            end
          end

          { attributes:, contents: }
        end
      end

      private_constant :Dispatch

      protected

        attr_writer :children, :attributes
    end
  end
end
