# frozen_string_literal: true

require "rufo"

module Sevgi
  module Derender
    class Node
      attr_reader :node, :pres, :type

      def initialize(node, pres = [])
        @node = node
        @pres = pres
        @type = dispatch
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

      def attributes! = attributes

      def children
        @children ||= node.children.map { self.class.new(it) }.reject do
          (it.node.text? and it.node.text.strip.empty?) or it.type == :Junk
        end
      end

      def content = @content ||= node.content.strip

      def derender = ruby(compile(pres).join("\n"))

      def element = name

      def evaluate(element, include_current = true)
        return element.instance_eval(derender) if include_current

        children.each { element.instance_eval(it.derender) }
      end

      def evaluate!(element) = evaluate(element, false)

      def name = @name ||= node.name

      def namespaces
        @namespaces ||= node.namespaces.to_h do |namespace, uri|
          [ namespace, uri ]
        end
      end

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
          end.tap { extend Elements.const_get(it) }
        end

        def ruby(unformatted_ruby)
          Rufo::Formatter.format(unformatted_ruby)
        rescue Rufo::SyntaxError
          raise unformatted_ruby
        end
    end
  end
end
