# frozen_string_literal: true

module Sevgi
  module Graphics
    # SVG element node used by the graphics DSL.
    #
    # @!method self.valid?(name)
    #   Reports whether a candidate can dispatch as an SVG element name.
    #   With Standard loaded, the name must be known; standalone Graphics accepts any valid XML name.
    #   @param name [Object] candidate element name
    #   @return [Boolean]
    class Element
      # Builds an element node.
      # @param name [Symbol, String] SVG element name
      # @param parent [Sevgi::Graphics::Element] parent element
      # @yield evaluates the drawing DSL in the new element
      # @yieldreturn [Object] ignored block result
      # @return [Sevgi::Graphics::Element]
      # @raise [Sevgi::ArgumentError] when an argument cannot be parsed as attributes or content
      # @raise [Sevgi::ArgumentError] when the element name or an attribute is not valid XML
      def self.element(name, *, parent:, &block) = new(name, **Dispatch.parse(name, *), parent:, &block)

      # Builds an SVG root element.
      # @yield evaluates the drawing DSL in the root element
      # @yieldreturn [Object] ignored block result
      # @return [Sevgi::Graphics::Element]
      # @raise [Sevgi::ArgumentError] when a root attribute is not valid XML
      def self.root(*, &block) = element(:svg, *, parent: RootParent, &block)

      # Reports whether an element is the root element.
      # @param element [Sevgi::Graphics::Element] element to test
      # @return [Boolean]
      def self.root?(element) = Element.send(:tree_parent, element).equal?(RootParent)

      class << self
        private

        def attach(element, parent, index: nil)
          children = tree_children(parent)
          index ? children.insert(index, element) : children << element
          element.instance_variable_set(:@parent, parent)
        end

        def detach(element)
          parent = tree_parent(element)
          tree_children(parent).delete(element) if parent.is_a?(element.class)
          element.instance_variable_set(:@parent, DetachedParent)
        end

        def tree_children(element) = element.instance_variable_get(:@children)

        def tree_parent(element) = element.instance_variable_get(:@parent)
      end

      class << self
        require "sevgi/standard"

        # Reports whether a candidate can dispatch as a known SVG element name.
        # @param name [Object] candidate element name
        # @return [Boolean]
        def valid?(name)
          Standard.element?(name)
        rescue Sevgi::ArgumentError
          false
        end

      rescue ::LoadError => e
        raise unless e.path == "sevgi/standard"

        # Reports whether a candidate can dispatch as a valid XML element name.
        # @param name [Object] candidate element name
        # @return [Boolean]
        def valid?(name)
          return false unless name.is_a?(::String) || name.is_a?(::Symbol)

          XML.name(name, context: "SVG element name")
          true
        rescue Sevgi::ArgumentError
          false
        end
      end

      private_class_method :new

      # Sentinel parents used by root and detached elements.
      RootParent = Object.new.tap { def it.inspect = "RootParent" }.freeze
      DetachedParent = Object.new.tap { def it.inspect = "DetachedParent" }.freeze

      private_constant :DetachedParent, :RootParent

      # SVG element method-name normalization.
      # @api private
      module Ident
        # Normalizes a Ruby method name into an SVG element id.
        # @param given [Symbol, String] method name
        # @return [Symbol]
        def id(given) = (@id ||= {})[given] ||= given.to_s.tr("_", "-").to_sym
      end

      extend Ident
      private_class_method :id
      private_constant :Ident

      # Returns the SVG element name.
      # @return [Symbol]
      attr_reader :name

      # Returns the attribute store.
      # @return [Sevgi::Graphics::Attributes]
      attr_reader :attributes

      # Returns a read-only snapshot of child elements in rendering order.
      # @return [Array<Sevgi::Graphics::Element>] frozen child snapshot
      def children = @children.dup.freeze

      # Returns a read-only snapshot of element content objects in rendering order.
      # @return [Array<Sevgi::Graphics::Content>] frozen content snapshot
      def contents = @contents.dup.freeze

      # Returns the parent element.
      # @return [Sevgi::Graphics::Element, nil] parent element, or nil for a root or detached element
      # @note Use `Root?` to distinguish a document root from a detached subtree root.
      def parent
        @parent if @parent.is_a?(self.class)
      end

      # Creates an element.
      # @param name [Symbol] SVG element name
      # @param parent [Sevgi::Graphics::Element, Object] parent element or root sentinel
      # @param attributes [Hash] SVG attributes
      # @param contents [Array<Sevgi::Graphics::Content>] content objects
      # @yield evaluates the drawing DSL in the new element
      # @yieldreturn [Object] ignored block result
      # @return [void]
      # @raise [Sevgi::ArgumentError] when the element name or an attribute is not valid XML
      # @api private
      def initialize(name, parent:, attributes: {}, contents: [], &block)
        unless name.is_a?(::String) || name.is_a?(::Symbol)
          ArgumentError.("XML element name must be a String or Symbol")
        end

        @name = XML.name(name, context: "XML element name").to_sym
        @attributes = Attributes.new(attributes)
        @children = []
        @contents = contents.dup
        @parent = parent

        Element.send(:attach, self, parent) unless Element.root?(self)

        instance_exec(&block) if block
      end

      # Dispatches SVG element DSL calls and caches valid element methods.
      # @param name [Symbol] missing method name
      # @yield evaluates the drawing DSL in the dispatched child element
      # @yieldreturn [Object] ignored block result
      # @return [Sevgi::Graphics::Element]
      # @raise [NameError] when the name is not a valid SVG element
      # @raise [Sevgi::ArgumentError] when an argument cannot be parsed as attributes or content
      def method_missing(name, *, &block)
        Element.valid?(tag = Element.send(:id, name)) ? Dispatch.(self, name, tag, *, &block) : super
      end

      # Reports whether a missing method can dispatch to an SVG element.
      # @param name [Symbol] queried method name
      # @param include_private [Boolean] standard Ruby respond_to? flag
      # @return [Boolean]
      # @api private
      def respond_to_missing?(name, include_private = false)
        Element.valid?(Element.send(:id, name)) || super
      end

      private :method_missing, :respond_to_missing?

      # Element method-missing parser and cache.
      # @api private
      module Dispatch
        extend self

        # Dispatches an element DSL call.
        # @param element [Sevgi::Graphics::Element] parent element
        # @param method [Symbol] Ruby method name
        # @param tag [Symbol] SVG element name
        # @return [Sevgi::Graphics::Element]
        def call(element, method, tag, *, &)
          unless Element.method_defined?(method)
            Element.class_exec do
              define_method(method) { |*args, &block| self.class.element(tag, *args, parent: self, &block) }
            end
          end

          element.public_send(method, *, &)
        end

        # Parses element DSL arguments.
        # @param name [Symbol] SVG element name
        # @param args [Array<Object>] positional DSL arguments
        # @return [Hash] parsed :attributes and :contents
        # @raise [Sevgi::ArgumentError] when an argument is not a Hash, String, or Content
        def parse(name, *args)
          attributes, contents = {}, []

          args.each do |arg|
            case arg
            when ::Hash
              attributes = arg
            when ::String
              contents << Content.encoded(arg)
            when Content
              contents << arg
            else
              ArgumentError.("Argument of element '#{name}' must be a Hash or String: #{arg}")
            end
          end

          {attributes:, contents:}
        end
      end

      private_constant :Dispatch

      protected

      attr_writer :attributes, :children, :contents, :parent
    end
  end
end
