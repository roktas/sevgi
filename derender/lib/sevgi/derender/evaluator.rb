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
        case node.type
        when :CSS
          append_css(node)
        when :Text
          parent.Element(:_, node.content)
        else
          append_element(node)
        end
      end

      private

      attr_reader :parent

      def append_css(node)
        return unless (hash = Css.to_h(node.node.content))

        parent.Element(:style, Graphics::Content.css(hash), type: "text/css", **node.attributes)
      end

      def append_element(node)
        parent.Element(node.name, *content(node), **attributes(node)).tap do |element|
          node.children.each { self.class.new(element).append(it) } unless content(node).any?
        end
      end

      def attributes(node) = node.attributes!

      def content(node)
        node.children.one? && node.children.first.node.text? ? [node.content] : []
      end
    end

    private_constant :Evaluator
  end
end
