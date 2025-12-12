# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require "erb"
require "rufo"

module Sevgi
  module Derender
    class Node
      using Refinements

      attr_reader :node, :attributes, :meta

      # Initializes with a Nokogiri XML node
      def initialize(node)
        @node = node
        @meta = {}

        @attributes = attributes!
      end

      def call(element, include_current = true)
        return element.instance_eval(render) if include_current

        children.each { element.instance_eval(it.render) }
      end

      def find(arg, by: "id")
        return self if attributes[by] == arg

        children&.each do
          found = it.find(arg, by:)

          return found if found
        end

        nil
      end

      # Returns formatted Ruby code
      def render
        @render ||= Rufo::Formatter.format(ruby_code)
      rescue Rufo::SyntaxError
        raise ruby_code
      end

      def inspect
        "#<#{self.class} name=#{name}, type=#{type}>"
      end

      # Returns the tag name
      def name
        node.name
      end

      # Returns one of our internal types (symbol)
      def type
        @type ||= type!
      end

      # Returns the content (body) of the element
      def content
        @content ||= content!
      end

      # Returns an array of children elements (Node)
      def children
        @children ||= children!
      end

      # Returns the ruby code, unformatted
      def ruby_code
        erb erb_template
      end

      private

        # Returns true if the element should be ignored
        def rejected?
          (node.text? and node.text.strip.empty?) or type == :junk
        end

        # Renders ERB code
        def erb(code)
          ERB.new(code, trim_mode: "%-").result(binding)
        end

        # Returns the content of the appropriate ERB tempalte, based on type
        def erb_template
          @erb_template ||= File.read(erb_template_file)
        end

        # Returns the path to the appropriate ERB template, based on type
        def erb_template_file
          file = type == :root ? "root" : type
          File.expand_path("templates/#{file}.erb", __dir__)
        end

        # Returns the internal element type
        def type!
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

        # Returns a filtered list of Node children
        def children!
          node.children.map { |child| Node.new(child) }.reject(&:rejected?)
        end

        META_NAMESPACE = "_"

        # Returns a hash of attributes
        def attributes!
          node.attribute_nodes.to_h do |attr|
            name = attr.name
            value = attr.value
            namespace= attr.namespace

            # FIXME: .
            if name.start_with?("#{META_NAMESPACE}:")
              meta[name.delete_prefix("#{META_NAMESPACE}:")] = value
            end

            key = if attr.respond_to?(:namespace) && (namespace = attr.namespace) && (prefix = namespace.prefix)
              meta[name] = value if prefix == META_NAMESPACE
              "#{prefix}:#{name}"
            else
              name
            end

            [ key, value ]
          end
        end

        def content!
          if type == :css
            CSS.new(node.content).to_h
          elsif node.content.is_a? String
            node.content.strip
          else
            # TODO: do we need this?
            # :nocov:
            node.content
            # :nocov:
          end
        end
    end
  end
end
