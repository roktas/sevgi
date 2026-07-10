# frozen_string_literal: true

require "nokogiri"

module Sevgi
  module Derender
    # Parsed SVG/XML document wrapper used by the derender pipeline.
    class Document
      # Loads and parses an SVG/XML file.
      #
      # Each call reads the current file content and returns an isolated parsed document. Caller mutation of one loaded
      # document does not affect later loads of the same path.
      # @param path [String] path to the source file, with or without `.svg` extension
      # @return [Sevgi::Derender::Document] document wrapper
      # @raise [Sevgi::ArgumentError] when the file cannot be found or file content is malformed XML
      # @raise [Errno::EACCES] when the file cannot be read
      def self.load_file(path)
        entry = ::File.expand_path(F.qualify(path, "svg"))

        ArgumentError.("File not found: #{path}") unless ::File.exist?(entry)

        content = ::File.read(entry)
        new(content)
      end

      # Parses SVG/XML content in strict XML mode.
      # @param content [String] SVG/XML source content
      # @return [Nokogiri::XML::Document] parsed XML document
      # @raise [Sevgi::ArgumentError] when content is not well-formed XML
      # @raise [Sevgi::ArgumentError] when content has no root element
      def self.parse(content)
        Nokogiri::XML(content.to_s.lstrip, &:strict).tap do |doc|
          ArgumentError.("XML document has no root element") unless doc.root
        end

      rescue Nokogiri::XML::SyntaxError => e
        raise ArgumentError, "Malformed XML: #{e.message.lines.first.strip}", cause: e
      end

      # Extracts the XML declaration from SVG/XML content.
      # @param content [String] SVG/XML source content
      # @return [String, nil] XML declaration line, if present
      def self.declaration(content)
        return unless (content = content.to_s.lstrip).start_with?("<?xml ")

        content[/\A<\?xml\b.*?\?>/m]
      end

      # @!attribute [r] doc
      #   @return [Nokogiri::XML::Document] parsed XML document
      # @!attribute [r] decl
      #   @return [String, nil] XML declaration line, if present
      attr_reader :doc, :decl

      # Builds a parsed document wrapper from SVG/XML content.
      # @param content [String] SVG/XML source content
      # @return [void]
      # @raise [Sevgi::ArgumentError] when content is malformed XML
      # @raise [Sevgi::ArgumentError] when content has no root element
      def initialize(content)
        @doc = self.class.parse(content)
        @decl = self.class.declaration(content)
      end

      # Converts the root or selected node into a derender node.
      # @param id [String, nil] optional SVG id selecting a node inside the document
      # @return [Sevgi::Derender::Node] selected node in the derender tree
      # @raise [Sevgi::ArgumentError] when the document has no root element or the id is absent
      def decompile(id = nil)
        if id
          if (found = doc.xpath("//*[@id=#{xpath_literal(id)}]") || []).empty?
            ArgumentError.("No such element with id '#{id}' in document")
          end

          found.first
        else
          doc.root
        end => element

        ArgumentError.("XML document has no root element") unless element

        Node.new(element, pres, namespaces: namespace_scope(element))
      end

      # Returns XML declaration and pre-root nodes preserved for root decompilation. The result contains only String
      # lines and omits the declaration when the source did not provide one.
      # @return [Array<String>] preamble XML lines
      def pres
        @pres ||= [].tap do |lines|
          lines.append(*doc.children.take_while { |node| node != doc.root }.map(&:to_xml))
          lines.unshift(decl) if decl && lines.first != decl
          lines.compact!
        end
      end

      private

      def namespace_scope(element)
        element == doc.root ? local_namespaces(element) : element.namespaces
      end

      def local_namespaces(element)
        return {} unless element.respond_to?(:namespace_definitions)

        element.namespace_definitions.to_h do |namespace|
          [namespace.prefix ? "xmlns:#{namespace.prefix}" : "xmlns", namespace.href]
        end
      end

      def xpath_literal(value)
        value = value.to_s

        return "'#{value}'" unless value.include?("'")
        return "\"#{value}\"" unless value.include?("\"")

        parts = value.split("'", -1).flat_map.with_index do |part, index|
          index.zero? ? [part] : ["'", part]
        end

        "concat(#{parts.map { |part| part == "'" ? "\"'\"" : "'#{part}'" }.join(", ")})"
      end
    end
  end
end
