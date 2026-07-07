# frozen_string_literal: true

module Sevgi
  module Derender
    # Node in a derender tree produced from an SVG/XML node.
    class Node
      # @!attribute [r] node
      #   @return [Nokogiri::XML::Node] source XML node
      # @!attribute [r] pres
      #   @return [Array<String>] preamble XML lines carried by the root node
      # @!attribute [r] type
      #   @return [Symbol] dispatch type used by derender element strategies
      attr_reader :node, :pres, :type

      # Builds a derender node.
      # @param node [Nokogiri::XML::Node] source XML node
      # @param pres [Array<String>] preamble XML lines carried by the root node
      # @return [void]
      def initialize(node, pres = [])
        @node = node
        @pres = pres
        @type = dispatch
      end

      # Attribute namespace prefix used for Sevgi metadata.
      META_NAMESPACE = "_:"

      # Returns Sevgi metadata attributes without the metadata namespace prefix.
      # @return [Hash{String => String}] metadata attributes
      def _
        @_ ||= attributes
          .slice(
            *attributes.keys.select { |key| key.start_with?(META_NAMESPACE) }
          )
          .transform_keys! { |key| key.delete_prefix(META_NAMESPACE) }
      end

      alias meta _

      # Returns source XML attributes keyed with namespace prefixes when present.
      # @return [Hash{String => String}] XML attributes
      def attributes
        @attributes ||= node.attribute_nodes.to_h do |attr|
          name, value = attr.name, attr.value

          if attr.respond_to?(:namespace) && (namespace = attr.namespace) && (prefix = namespace.prefix)
            "#{prefix}:#{name}"
          else
            name
          end => key

          [key, value]
        end
      end

      # Returns source XML attributes.
      # @return [Hash{String => String}] XML attributes
      def attributes! = attributes

      # Returns non-ignorable child derender nodes.
      # @return [Array<Sevgi::Derender::Node>] child nodes
      def children
        @children ||= node
          .children
          .map { |child| self.class.new(child) }
          .reject { |child| ignorable_child?(child) }
      end

      # Returns node text content, preserving or stripping whitespace according to xml:space.
      # @return [String]
      def content = @content ||= preserve_space? ? node.content : node.content.strip

      # Converts this node into formatted Sevgi DSL Ruby source.
      # @return [String] formatted Sevgi DSL source
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      def derender = Ruby.format(decompile(pres).join("\n"))

      # Returns the Sevgi DSL element name for this node.
      # @return [String]
      def element = name

      # Evaluates this node under a graphics element.
      # @param element [Sevgi::Graphics::Element] target graphics element
      # @param include_current [Boolean] true to evaluate this node, false to evaluate only children
      # @return [Sevgi::Graphics::Element] target graphics element
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      def evaluate(element, include_current = true)
        return element.instance_eval(derender) if include_current

        children.each { element.instance_eval(it.derender) }
      end

      # Evaluates only this node's children under a graphics element.
      # @param element [Sevgi::Graphics::Element] target graphics element
      # @return [Sevgi::Graphics::Element] target graphics element
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      def evaluate!(element) = evaluate(element, false)

      # Finds the first descendant whose attribute matches a value.
      # @param arg [String] attribute value to find
      # @param by [String] attribute name used for lookup
      # @return [Sevgi::Derender::Node, nil] matching node, or nil
      def find(arg, by: "id")
        return self if attributes[by] == arg

        children&.each do |child|
          found = child.find(arg, by:)

          return found if found
        end

        nil
      end

      # Returns the source XML node name.
      # @return [String]
      def name = @name ||= node.name

      # Returns source XML namespaces.
      # @return [Hash{String => String}] namespace declarations
      def namespaces = (@namespaces ||= node.namespaces.to_h { |namespace, uri| [namespace, uri] })

      # Reports whether this node is the SVG root strategy.
      # @return [Boolean]
      def root? = type == :Root

      private

      def dispatch
        if node.text?
          :Text
        elsif node.comment?
          :Junk
        elsif node.name == "style"
          :CSS
        elsif node.name == "svg"
          :Root
        else
          :Any
        end
          .tap { extend(Elements.const_get(it)) }
      end

      def ignorable_child?(child)
        child.type == :Junk || (child.node.text? && child.node.text.strip.empty? && !child.preserve_space?)
      end

      protected

      def preserve_space?
        each_node do |current|
          case xml_space(current)
          when "preserve"
            return true
          when "default"
            return false
          end
        end

        false
      end

      private

      def each_node
        current = node

        while current
          yield current
          current = current.respond_to?(:parent) ? current.parent : nil
        end
      end

      def xml_space(current)
        return unless current.respond_to?(:attribute_nodes)

        current.attribute_nodes.find { xml_space_attribute?(it) }&.value
      end

      def xml_space_attribute?(attribute) = attribute.name == "space" && attribute.namespace&.prefix == "xml"
    end
  end
end
