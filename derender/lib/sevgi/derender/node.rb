# frozen_string_literal: true

module Sevgi
  module Derender
    # Namespace classifier for derender strategies.
    # @api private
    module Namespace
      SVG = "http://www.w3.org/2000/svg"
      private_constant :SVG

      def self.foreign?(node) = node.namespace && node.namespace.href != SVG

      def self.svg?(node, name)
        namespace = node.namespace

        node.name == name && (namespace.nil? || (namespace.prefix.nil? && namespace.href == SVG))
      end
    end

    private_constant :Namespace

    META_NAMESPACE = "_:"
    private_constant :META_NAMESPACE

    # Captures owned Node state during construction.
    # @api private
    module Capture
      private

      def capture_context(pres, namespaces)
        @pres = pres.map { it.to_s.dup.freeze }.freeze
        @namespaces = snapshot(namespaces || local_namespaces)
        @type = dispatch
        singleton_class.send(:private, :decompile)
      end

      def capture_children
        @children = node
          .children
          .map { self.class.send(:new, it, omit: @omit, top: false) }
          .reject { ignorable_child?(it) }
          .freeze
      end

      def capture_values
        @attributes = snapshot(
          node.attribute_nodes.filter_map do |attribute|
            key = attribute_key(attribute)
            [key, attribute.value] unless @omit.key?(key)
          end
        )
        @meta = snapshot(attributes.filter_map { |key, value| metadata(key, value) })
      end

      def capture_identity
        @content = (preserve_space? ? node.content : normalized_content).dup.freeze
        @name = [node.namespace&.prefix, node.name].compact.join(":").freeze
      end

      def metadata(key, value)
        [key.delete_prefix(META_NAMESPACE), value] if key.start_with?(META_NAMESPACE)
      end

      def snapshot(pairs)
        pairs
          .each_with_object({}) do |(key, value), result|
            result[key.to_s.dup.freeze] = value.to_s.dup.freeze
          end
          .freeze
      end
    end

    private_constant :Capture

    # Immutable conversion result for one SVG/XML node.
    #
    # Attributes, namespaces, content, and descendants are owned snapshots; parser objects and dispatch strategies
    # remain internal to Derender. Attributes omitted during decompilation are absent throughout the captured subtree.
    class Node
      include Capture

      private_class_method :new

      # Returns immutable XML attributes.
      # @return [Hash{String => String}] owned attribute snapshot
      attr_reader :attributes

      # Returns immutable child nodes.
      # @return [Array<Sevgi::Derender::Node>] owned child snapshot
      attr_reader :children

      # Returns immutable normalized text content. `xml:space="preserve"` and single-line mixed text retain their exact
      # text. Other text trims surrounding whitespace; multiline mixed text removes only its outer indentation lines.
      # @return [String] frozen owned text snapshot
      attr_reader :content

      # Returns the immutable qualified element name.
      # @return [String] owned element name
      attr_reader :name

      # Returns immutable namespace declarations emitted for this node. A conversion root owns its local declarations;
      # a separately selected node owns all declarations in scope; descendant snapshots own their local declarations.
      # @return [Hash{String => String}] frozen owned namespace snapshot
      attr_reader :namespaces

      # Builds an owned derender result.
      # @param node [Nokogiri::XML::Node] source XML node
      # @param pres [Array<String>] preamble XML lines carried by the root node
      # @param namespaces [Hash{String => String}, nil] namespace declarations to emit on this node
      # @param omit [Hash{String => Boolean}, nil] normalized attribute omission set shared by the captured subtree
      # @param top [Boolean] true when this node is the root of the current conversion
      # @return [void]
      # @api private
      def initialize(node, pres = [], namespaces: nil, omit: nil, top: true)
        @node = node
        @omit = omit || {}.freeze
        @top = top
        capture_context(pres, namespaces)
        capture_values
        capture_children
        capture_identity
        freeze
      end

      # Returns Sevgi metadata attributes without the metadata namespace prefix.
      # @return [Hash{String => String}] immutable metadata snapshot
      def _ = @meta

      alias meta _

      # Converts this node into formatted Sevgi DSL Ruby source.
      # @return [String] formatted Sevgi DSL source
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      # @note Foreign namespace elements use the explicit `Element` DSL path, and nested `svg` nodes remain elements.
      # @note Unsafe bare Ruby names are emitted through the explicit `Element` DSL word.
      def derender = Ruby.format(decompile(@pres).join("\n"))

      # Evaluates this node under a graphics element.
      # @param element [Sevgi::Graphics::Element] target graphics element
      # @return [Sevgi::Graphics::Element, nil] included current element, or nil when it produces no graphics output
      # @note Namespace declarations, qualified attributes, significant text, and nested `svg` nodes are preserved.
      def evaluate(element) = Evaluator.new(element).append(self)

      # Evaluates only this node's children under a graphics element.
      # @param element [Sevgi::Graphics::Element] target graphics element
      # @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
      def evaluate_children(element) = children.filter_map { it.evaluate(element) }.freeze

      # Finds this node or the first descendant whose attribute matches a value.
      # @param arg [String] attribute value to find
      # @param by [String] attribute name used for lookup
      # @return [Sevgi::Derender::Node, nil] matching immutable node, or nil
      # @note Attributes omitted during decompilation are unavailable for later searches.
      def find(arg, by: "id")
        return self if attributes[by] == arg

        children.lazy.map { it.find(arg, by:) }.find(&:itself)
      end

      # Reports whether this node represents an SVG document root.
      # @return [Boolean] true for the conversion root strategy
      def root? = @type == :Root

      private

      attr_reader :node, :type

      def all_attributes = {**attributes, **namespaces}.freeze

      def attribute_key(attribute) = [attribute.namespace&.prefix, attribute.name].compact.join(":")

      def dispatch
        case
        when node.text?
          :Text
        when node.comment?
          :Junk
        when Namespace.svg?(node, "style")
          :CSS
        when @top && Namespace.svg?(node, "svg")
          :Root
        else
          :Any
        end
          .tap { extend(Elements.const_get(it)) }
      end

      def element = name

      def ignorable_child?(child)
        child.send(:type) == :Junk ||
          (child.send(:text?) &&
            child.content.strip.empty? &&
            !child.send(:preserve_space?) &&
            !child.send(:inline_text?))
      end

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

      def text? = node.text?

      def xml_space(current)
        return unless current.respond_to?(:attribute_nodes)

        current.attribute_nodes.find { xml_space_attribute?(it) }&.value
      end

      def xml_space_attribute?(attribute) = attribute.name == "space" && attribute.namespace&.prefix == "xml"
    end
  end
end
