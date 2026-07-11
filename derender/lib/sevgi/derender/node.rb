# frozen_string_literal: true

module Sevgi
  module Derender
    # Namespace domain classifier for derender strategies.
    # @api private
    module Domain
      SVG = "http://www.w3.org/2000/svg"
      private_constant :SVG

      def self.foreign?(node) = node.namespace && node.namespace.href != SVG

      def self.svg?(node, name)
        namespace = node.namespace

        node.name == name && (namespace.nil? || (namespace.prefix.nil? && namespace.href == SVG))
      end
    end

    private_constant :Domain

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
      # @param namespaces [Hash{String => String}, nil] namespace declarations to emit on this node; selected roots use
      #   their full inherited namespace scope, while ordinary children use only declarations from their own element
      # @param top [Boolean] true when this node is the root of the current conversion
      # @return [void]
      def initialize(node, pres = [], namespaces: nil, top: true)
        @node = node
        @pres = pres
        @namespaces = namespaces
        @top = top
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
      def attributes = @attributes ||= node.attribute_nodes.to_h { [attribute_key(it), it.value] }

      # Returns source XML attributes and namespace declarations emitted on this node.
      # @return [Hash{String => String}] XML attributes
      def attributes! = {**attributes, **namespaces}

      # Returns non-ignorable child derender nodes.
      # @return [Array<Sevgi::Derender::Node>] child nodes
      def children
        @children ||= node
          .children
          .map { |child| self.class.new(child, top: false) }
          .reject { |child| ignorable_child?(child) }
      end

      # Returns node text content.
      #
      # `xml:space="preserve"` keeps content verbatim. Default-space text nodes are stripped for ordinary pretty-printed
      # content; line-break indentation around mixed-content children is removed while inline boundary spaces and tabs are
      # kept because they affect rendered SVG text.
      # @return [String]
      def content = @content ||= preserve_space? ? node.content : normalized_content

      # Converts this node into formatted Sevgi DSL Ruby source.
      # @return [String] formatted Sevgi DSL source
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      # @note Foreign namespace elements use the explicit `Element` DSL path, and nested `svg` nodes remain elements.
      # @note Unsafe bare Ruby names are emitted through the explicit `Element` DSL word.
      def derender = Ruby.format(decompile(pres).join("\n"))

      # Returns the Sevgi DSL element name for this node.
      # @return [String]
      def element = name

      # Evaluates this node under a graphics element.
      # @param element [Sevgi::Graphics::Element] target graphics element
      # @param include_current [Boolean] true to evaluate this node, false to evaluate only children
      # @return [Sevgi::Graphics::Element, Array<Sevgi::Graphics::Element>, nil] included current element, included child
      #   elements when include_current is false, or nil when the node does not produce graphics output
      # @note Namespace declarations, qualified attributes, significant text, and nested `svg` nodes are preserved.
      def evaluate(element, include_current = true)
        return Evaluator.new(element).append(self) if include_current

        evaluate_children(element)
      end

      # Evaluates only this node's children under a graphics element.
      # @param element [Sevgi::Graphics::Element] target graphics element
      # @return [Array<Sevgi::Graphics::Element>] included child elements
      def evaluate_children(element) = children.map { it.evaluate(element) }.compact

      # Finds the first descendant whose attribute matches a value.
      # @param arg [String] attribute value to find
      # @param by [String] attribute name used for lookup
      # @return [Sevgi::Derender::Node, nil] matching node, or nil
      def find(arg, by: "id")
        return self if attributes[by] == arg

        children.lazy.map { it.find(arg, by:) }.find(&:itself)
      end

      # Returns the source XML qualified name, including its namespace prefix when present.
      # @return [String]
      def name = @name ||= [node.namespace&.prefix, node.name].compact.join(":")

      # Returns source XML namespace declarations emitted on this node.
      # @return [Hash{String => String}] namespace declarations
      def namespaces = (@namespaces ||= local_namespaces)

      # Reports whether this node is the SVG root strategy.
      # @return [Boolean]
      def root? = type == :Root

      private

      def attribute_key(attribute) = [attribute.namespace&.prefix, attribute.name].compact.join(":")

      def dispatch
        case
        when node.text?
          :Text
        when node.comment?
          :Junk
        when Domain.svg?(node, "style")
          :CSS
        when @top && Domain.svg?(node, "svg")
          :Root
        else
          :Any
        end
          .tap { extend(Elements.const_get(it)) }
      end

      def ignorable_child?(child)
        child.type == :Junk ||
          (child.node.text? && child.node.text.strip.empty? && !child.preserve_space? && !child.inline_text?)
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

      def inline_text? = mixed_text? && !node.content.match?(/[\r\n]/)

      private

      def normalized_content
        return node.content if mixed_text? && inline_text?
        return node.content.strip unless mixed_text?

        node.content.sub(/\A[ \t]*\r?\n[ \t]*/, "").sub(/[ \t]*\r?\n[ \t]*\z/, "")
      end

      def mixed_text? = node.text? && node.parent&.children&.any?(&:element?)

      def local_namespaces
        return {} unless node.respond_to?(:namespace_definitions)

        node.namespace_definitions.to_h do |namespace|
          [namespace.prefix ? "xmlns:#{namespace.prefix}" : "xmlns", namespace.href]
        end
      end

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
