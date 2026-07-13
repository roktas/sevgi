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
      # @return [Sevgi::Graphics::Element, nil] included element, or nil when the node does not produce graphics output
      def append(node)
        case node.send(:type)
        when :CSS
          append_css(node)
        when :Text
          build(:_, node.content)
        else
          append_element(node)
        end
      end

      private

      attr_reader :parent

      def append_css(node)
        content = if (hash = Css.rules(node.content))
          Graphics::Content.css(hash)
        else
          Graphics::Content.cdata(node.content)
        end

        build(:style, content, **node.send(:all_attributes))
      end

      def append_element(node)
        contents = contents(node)

        build(node.name, *contents, **attributes(node)).tap do |element|
          node.children.each { self.class.new(element).append(it) } if contents.empty?
        end
      end

      def attributes(node)
        attributes = node.send(:all_attributes)
        return attributes unless (style = attributes["style"])
        return attributes unless (declarations = Css.declarations(style))

        {**attributes, "style" => declarations}
      end

      def contents(node)
        node.children.one? && node.children.first.send(:text?) ? [node.content] : []
      end

      def build(name, *contents, **attributes)
        parent.class.element(name.to_sym, *contents, attributes, parent:)
      end
    end

    private_constant :Evaluator
  end
end
