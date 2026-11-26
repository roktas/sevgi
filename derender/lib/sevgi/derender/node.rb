# frozen_string_literal: true

module Sevgi
  module Derender
    # Namespace classifier for derender strategies.
    # @api private
    module Namespace
      SVG = "http://www.w3.org/2000/svg"

      def self.foreign?(node, scope)
        namespace = node.namespace
        namespace ? namespace.href != SVG : scope.key?("xmlns")
      end

      def self.root?(node, foreign)
        return unqualified?(node, "svg", foreign) unless node == node.document.root

        node.name == "svg" && (!node.namespace || node.namespace.href == SVG)
      end

      def self.unqualified?(node, name, foreign) = !foreign && node.name == name && node.namespace&.prefix.nil?
    end

    private_constant :Namespace

    # Stateless Nokogiri DOM inspection helpers for {Capture}.
    # @api private
    module DOM
      class << self
        def attribute_key(attribute) = [attribute.namespace&.prefix, attribute.name].compact.join(":")

        def local_namespaces(node)
          return {} unless node.respond_to?(:namespace_definitions)

          node.namespace_definitions.to_h do |namespace|
            [namespace.prefix ? "xmlns:#{namespace.prefix}" : "xmlns", namespace.href]
          end
        end

        def scope(node)
          declarations = node.namespaces
          declarations["xmlns"] ||= "" if node.document.root&.namespace&.prefix
          declarations
        end

        def mixed?(node) = node.children.any? { it.element? || it.cdata? || it.comment? || it.processing_instruction? }

        def parent_mixed?(node) = node.parent ? mixed?(node.parent) : false

        def preserve_space?(node, inherited)
          own = space_flag(node)
          return own unless own.nil?
          return inherited unless inherited.nil?

          each_ancestor(node) do |current|
            flag = space_flag(current)
            return flag unless flag.nil?
          end

          false
        end

        private

        def each_ancestor(node)
          current = node.respond_to?(:parent) ? node.parent : nil

          while current
            yield current
            current = current.respond_to?(:parent) ? current.parent : nil
          end
        end

        def space_flag(current)
          return unless current.respond_to?(:attribute_nodes)

          attribute = current.attribute_nodes.find { it.name == "space" && it.namespace&.prefix == "xml" }
          {"preserve" => true, "default" => false}[attribute&.value]
        end
      end
    end

    private_constant :DOM

    META_NAMESPACE = "_:"
    private_constant :META_NAMESPACE

    # Captures owned Node state during construction.
    # @api private
    module Capture
      NODE_TYPES = {
        Nokogiri::XML::Node::TEXT_NODE => :Text,
        Nokogiri::XML::Node::CDATA_SECTION_NODE => :CData,
        Nokogiri::XML::Node::COMMENT_NODE => :Comment,
        Nokogiri::XML::Node::PI_NODE => :Instruction
      }.freeze

      private

      def capture_children(node)
        child_context = [@preserve_space, DOM.mixed?(node)]
        children = node.children.map { self.class.send(:new, it, omit: @omit, inherited: child_context) }
        @children = children.reject { ignorable_child?(it) }.freeze
      end

      def capture_context(node, pres, namespaces, inherited)
        @scope = snapshot(DOM.scope(node))
        capture_flags(node, inherited)
        @pres = pres.map { it.to_s.dup.freeze }.freeze
        @namespaces = snapshot(namespaces || DOM.local_namespaces(node))
        @type = dispatch(node)
        singleton_class.send(:private, :decompile)
      end

      def capture_flags(node, inherited)
        preserve_space, mixed_parent = inherited
        @text = node.text?
        @foreign = Namespace.foreign?(node, @scope)
        @preserve_space = DOM.preserve_space?(node, preserve_space)
        @mixed_text = @text && (mixed_parent.nil? ? DOM.parent_mixed?(node) : mixed_parent)
        @inline_text = @mixed_text && !node.content.match?(/[\r\n]/)
      end

      def capture_identity(node)
        raw_content = node.content
        @inline_content = inline_parent_content?(node)
        @css = raw_content.dup.freeze if @type == :Style
        @content = captured_content(node, raw_content).dup.freeze
        @name = [node.namespace&.prefix, node.name].compact.join(":").freeze
      end

      def capture_values(node)
        @attributes = snapshot(
          node.attribute_nodes.filter_map do |attribute|
            key = DOM.attribute_key(attribute)
            [key, attribute.value] unless @omit.key?(key)
          end
        )
        @meta = snapshot(attributes.filter_map { |key, value| metadata(key, value) })
      end

      def captured_content(node, raw_content)
        return node.to_xml if node.processing_instruction?

        literal_content?(node) || @preserve_space ? raw_content : normalized_content(raw_content)
      end

      def dispatch(node)
        type = NODE_TYPES[node.type]
        type ||= if Namespace.unqualified?(node, "style", @foreign) && node.children.all? { it.text? || it.cdata? }
          :Style
        elsif @top && Namespace.root?(node, @foreign)
          :Root
        else
          :Any
        end

        type.tap { extend(Elements.const_get(it)) }
      end

      def ignorable_child?(child)
        child.send(:text?) &&
          child.content.strip.empty? &&
          !child.send(:preserve_space?) &&
          !child.send(:inline_text?)
      end

      def inline_parent_content?(node)
        return false unless children.any? { it.send(:text?) || it.send(:type) == :CData }

        @preserve_space || node.children.none? { it.text? && it.content.match?(/[\r\n]/) }
      end

      def literal_content?(node) = node.cdata? || node.comment?

      def metadata(key, value)
        [key.delete_prefix(META_NAMESPACE), value] if key.start_with?(META_NAMESPACE)
      end

      def normalized_content(raw_content)
        return raw_content if @mixed_text && @inline_text
        return raw_content.strip unless @mixed_text

        raw_content.sub(/\A[ \t]*\r?\n[ \t]*/, "").sub(/[ \t]*\r?\n[ \t]*\z/, "")
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
    # Attributes, namespaces, content, and descendants are owned snapshots. Parser objects and dispatch strategies
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
      # text. Other text trims surrounding whitespace. Multiline mixed text removes only its outer indentation lines.
      # For a processing instruction, content is its complete XML markup, including the target and data.
      # @return [String] frozen owned text snapshot
      attr_reader :content

      # Returns the immutable qualified element name.
      # @return [String] owned element name
      attr_reader :name

      # Returns immutable namespace declarations emitted for this node. A conversion root owns its local declarations.
      # A separately selected node owns all declarations in scope. Descendant snapshots own their local declarations.
      # Independent source conversion and evaluation also emit the inherited declarations captured for that node.
      # @return [Hash{String => String}] frozen owned namespace snapshot
      attr_reader :namespaces

      # Builds an owned derender result.
      # @param node [Nokogiri::XML::Node] source XML node
      # @param pres [Array<String>] preamble XML lines carried by the root node
      # @param namespaces [Hash{String => String}, nil] namespace declarations to emit on this node
      # @param omit [Hash{String => Boolean}, nil] normalized attribute omission set shared by the captured subtree
      # @param inherited [Array<Boolean>, nil] inherited `[preserve_space, mixed_parent]` flags from the parent
      # @return [void]
      # @api private
      def initialize(node, pres = [], namespaces: nil, omit: nil, inherited: nil)
        @omit = omit || {}.freeze
        @top = inherited.nil?
        capture_context(node, pres, namespaces, inherited)
        capture_values(node)
        capture_children(node)
        capture_identity(node)
        freeze
      end

      # Returns Sevgi metadata attributes without the metadata namespace prefix.
      # @return [Hash{String => String}] immutable metadata snapshot
      def _ = @meta

      alias meta _

      # Converts this node into formatted Sevgi DSL Ruby source. The returned String is ordinary Ruby source. Review and
      # integrate it statically rather than using Ruby's raw dynamic evaluation methods.
      # @return [String] formatted Sevgi DSL source
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      # @note Foreign namespace elements use the explicit `Element` DSL path, and nested `svg` nodes remain elements.
      # @note Unsafe bare Ruby names are emitted through the explicit `Element` DSL word.
      def derender = Ruby.format(decompile(@pres, namespaces: @scope).join("\n"))

      # Evaluates this node under a graphics element.
      # @param element [Sevgi::Graphics::Element] target graphics element
      # @return [Sevgi::Graphics::Element, nil] included current element, or nil when it produces no graphics output
      # @note Namespace declarations, qualified attributes, significant text, and nested `svg` nodes are preserved.
      def evaluate(element) = Evaluator.new(element).append(self, namespaces: @scope)

      # Evaluates only this node's children under a graphics element.
      # Each imported element retains its namespace scope without changing the target parent's declarations.
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

      attr_reader :css, :type

      def all_attributes(namespaces = self.namespaces()) = {**attributes, **namespaces}.freeze

      def element = name

      def foreign? = @foreign

      def inline_content? = @inline_content

      def inline_text? = @inline_text

      def preserve_space? = @preserve_space

      def text? = @text

      def text_leaf? = children.one? && children.first.send(:text?)
    end
  end
end
