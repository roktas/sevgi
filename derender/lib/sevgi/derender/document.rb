# frozen_string_literal: true

require "nokogiri"

module Sevgi
  module Derender
    # Parsed SVG/XML document wrapper used by the derender pipeline.
    class Document
      @cache = {}

      class << self
        # @return [Hash{String => Nokogiri::XML::Document}] parsed document cache keyed by expanded file path
        attr_reader :cache
      end

      # Loads and parses an SVG/XML file, using the parse cache when possible.
      # @param path [String] path to the source file, with or without `.svg` extension
      # @return [Sevgi::Derender::Document] document wrapper
      # @raise [Sevgi::ArgumentError] when the file cannot be found
      # @raise [Errno::EACCES] when the file cannot be read
      def self.load_file(path)
        entry = ::File.expand_path(F.qualify(path, "svg"))

        ArgumentError.("File not found: #{path}") unless ::File.exist?(entry)

        content = ::File.read(entry)
        new(content) do
          @doc = self.class.cache[entry] ||
            begin
              self.class.cache[entry] = self.class.parse(content)
            end
        end
      end

      # Parses SVG/XML content.
      # @param content [String] SVG/XML source content
      # @return [Nokogiri::XML::Document] parsed XML document
      def self.parse(content) = Nokogiri::XML(content)

      # Extracts the XML declaration from SVG/XML content.
      # @param content [String] SVG/XML source content
      # @return [String, nil] XML declaration line, if present
      def self.declaration(content)
        return unless (content = content.lstrip).start_with?("<?xml ")

        content.split("\n").first
      end

      # @!attribute [r] doc
      #   @return [Nokogiri::XML::Document] parsed XML document
      # @!attribute [r] decl
      #   @return [String, nil] XML declaration line, if present
      attr_reader :doc, :decl

      # Builds a parsed document wrapper from SVG/XML content.
      # @param content [String] SVG/XML source content
      # @yield optional initializer used by {load_file} to install cached parse state
      # @yieldreturn [void]
      # @return [void]
      def initialize(content, &block)
        instance_exec(&block) if block

        @doc ||= self.class.parse(content)
        @decl = self.class.declaration(content)
      end

      # Converts the root or selected node into a derender node.
      # @param id [String, nil] optional SVG id selecting a node inside the document
      # @return [Sevgi::Derender::Node] selected node in the derender tree
      # @raise [Sevgi::ArgumentError] when the id is absent
      def decompile(id = nil)
        if id
          if (found = doc.xpath("//*[@id=#{xpath_literal(id)}]") || []).empty?
            ArgumentError.("No such element with id '#{id}' in document")
          end

          found.first
        else
          doc.root
        end => element

        Node.new(element, pres)
      end

      # Returns XML declaration and pre-root nodes preserved for root decompilation.
      # @return [Array<String>] preamble XML lines
      def pres
        @pres ||= [].tap do |lines|
          lines.append(*doc.children.take_while { |node| node != doc.root }.map(&:to_xml))
          lines.unshift(decl) unless lines.first == decl
        end
      end

      private

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
