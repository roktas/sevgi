# frozen_string_literal: true

module Sevgi
  module Derender
    # Builds graphics element trees from derender nodes without evaluating Ruby source.
    # @api private
    class Evaluator
      # Builds an evaluator.
      # @param parent [Sevgi::Graphics::Element] target graphics parent
      # @return [void]
      def initialize(parent) = @parent = parent

      # Appends a derender node to the target parent.
      # @param node [Sevgi::Derender::Node] derender node
      # @param namespaces [Hash{String => String}] namespace declarations for the appended node
      # @return [Sevgi::Graphics::Element, nil] included element, or nil when the node does not produce graphics output
      def append(node, namespaces: node.namespaces)
        type = node.send(:type)
        return append_css(node, namespaces) if type == :CSS
        return build(:_, node.content) if type == :Text
        return append_cdata(node) if type == :CData
        return build(:_, Graphics::Content.verbatim("<!--#{node.content}-->")) if type == :Comment

        append_element(node, namespaces)
      end

      private

      attr_reader :parent

      def append_cdata(node)
        body = Graphics.const_get(:XML).cdata(node.content)
        build(:_, Graphics::Content.verbatim("<![CDATA[#{body}]]>"))
      end

      def append_css(node, namespaces)
        content = if (hash = Css.rules(node.content))
          Graphics::Content.css(hash)
        else
          Graphics::Content.cdata(node.content)
        end

        build(:style, content, **node.send(:all_attributes, namespaces))
      end

      def append_element(node, namespaces)
        contents = contents(node)

        build(node.name, *contents, **attributes(node, namespaces)).tap do |element|
          node.children.each { self.class.new(element).append(it) } unless node.send(:text_leaf?)
        end
      end

      def attributes(node, namespaces)
        attributes = node.send(:all_attributes, namespaces)
        return attributes unless (style = attributes["style"])
        return attributes unless (declarations = Css.declarations(style))

        {**attributes, "style" => declarations}
      end

      def contents(node)
        return [node.content] if node.send(:text_leaf?)

        node.send(:inline_content?) ? [""] : []
      end

      def build(name, *contents, **attributes)
        parent.class.element(name.to_sym, *contents, attributes, parent:)
      end
    end

    private_constant :Evaluator
  end
end
