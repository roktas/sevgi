# frozen_string_literal: true

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
        @_ ||= attributes
          .slice(
            *attributes.keys.select { |key| key.start_with?(META_NAMESPACE) }
          )
          .transform_keys! { |key| key.delete_prefix(META_NAMESPACE) }
      end

      alias meta _

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

      def attributes! = attributes

      def children
        @children ||= node
          .children
          .map { |child| self.class.new(child) }
          .reject { |child| ignorable_child?(child) }
      end

      def content = @content ||= preserve_space? ? node.content : node.content.strip

      def derender = Ruby.format(decompile(pres).join("\n"))

      def element = name

      def evaluate(element, include_current = true)
        return element.instance_eval(derender) if include_current

        children.each { element.instance_eval(it.derender) }
      end

      def evaluate!(element) = evaluate(element, false)

      def find(arg, by: "id")
        return self if attributes[by] == arg

        children&.each do |child|
          found = child.find(arg, by:)

          return found if found
        end

        nil
      end

      def name = @name ||= node.name

      def namespaces = (@namespaces ||= node.namespaces.to_h { |namespace, uri| [namespace, uri] })

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
