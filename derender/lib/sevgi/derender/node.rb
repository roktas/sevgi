# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require "erb"
require "rufo"

module Sevgi
  module Derender
    class Node
      attr_reader :node

      def initialize(node) = @node = node

      META_NAMESPACE = "_:"

      def _ = @_ ||= attributes.slice(
        *attributes.keys.select { |it| it.start_with?(META_NAMESPACE) }
      ).transform_keys! { it.delete_prefix(META_NAMESPACE) }

      alias_method :meta, :_

      def attributes = @attributes ||= node.attribute_nodes.to_h do |attr|
        name, value = attr.name, attr.value

        if attr.respond_to?(:namespace) && (namespace = attr.namespace) && (prefix = namespace.prefix)
          "#{prefix}:#{name}"
        else
          name
        end => key

        [ key, value ]
      end

      def [](attr) = attributes[attr]

      def call(element, include_current = true)
        if include_current
          element.instance_eval(ruby)
        else
          children.each { element.instance_eval(it.ruby) }
        end
      end

      def children = @children ||= node.children.map { self.class.new(it) }.reject do
        (it.node.text? and it.node.text.strip.empty?) or it.type == :junk
      end

      def content = @content ||= begin
        if type == :css
          CSS.new(node.content).to_h
        elsif node.content.is_a? String
          node.content.strip
        else
          # :nocov:
          node.content
          # :nocov:
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
          :text
        elsif node.comment?
          :junk
        elsif node.name == "style"
          :css
        elsif node.name == "svg"
          :root
        else
          :element
        end
      end

      private

        def erb(code) = ERB.new(code, trim_mode: "%-").result(binding)

        def erb_template = @erb_template ||= Template[type == :root ? "root" : type]

        def ruby_unformatted = erb(erb_template)
    end
  end
end
