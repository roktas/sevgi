# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require "rufo"

module Sevgi
  module Derender
    class Node
      attr_reader :node, :preambles

      def initialize(node, preambles = [])
        @node = node
        @preambles = preambles
      end

      META_NAMESPACE = "_:"

      def _
        @_ ||= attributes.slice(
          *attributes.keys.select { |it| it.start_with?(META_NAMESPACE) }
        ).transform_keys! { it.delete_prefix(META_NAMESPACE) }
      end

      alias_method :meta, :_

      def attributes
        @attributes ||= node.attribute_nodes.to_h do |attr|
          name, value = attr.name, attr.value

          if attr.respond_to?(:namespace) && (namespace = attr.namespace) && (prefix = namespace.prefix)
            "#{prefix}:#{name}"
          else
            name
          end => key

          [ key, value ]
        end
      end

      def namespaces
        @namespaces ||= node.namespaces.to_h do |namespace, uri|
          [ namespace, uri ]
        end
      end

      def [](attr) = attributes[attr]

      def call(element, include_current = true)
        if include_current
          element.instance_eval(ruby)
        else
          children.each { element.instance_eval(it.ruby) }
        end
      end

      def children
        @children ||= node.children.map { self.class.new(it) }.reject do
          (it.node.text? and it.node.text.strip.empty?) or it.type == :Junk
        end
      end

      def content
        @content ||= begin
          if type == :Css
            CSS.css_to_hash(node.content)
          elsif node.content.is_a?(::String)
            node.content.strip
          else
            # :nocov:
            node.content
            # :nocov:
          end
        end
      end

      def find(arg, by: "id")
        return self if attributes[by] == arg

        children&.each do
          if (found = it.find(arg, by:))
            return found
          end
        end

        nil
      end

      def inspect = "#<#{self.class} name=#{name}, type=#{type}>"

      def name = node.name

      def ruby
        @ruby ||= Rufo::Formatter.format(ruby_unformatted)
      rescue Rufo::SyntaxError
        raise ruby_unformatted
      end

      def type = @type ||= begin
        if node.text?
          :Text
        elsif node.comment?
          :Junk
        elsif node.name == "svg"
          :Root
        elsif node.name == "style"
          :Css
        else
          :Element
        end
      end

      private

        def ruby_unformatted = Render.template(type, binding)
    end
  end
end
