# frozen_string_literal: true

require "nokogiri"

module Sevgi
  module Derender
    class Document
      @cache = {}

      class << self
        attr_reader :cache
      end

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

      def self.parse(content) = Nokogiri::XML(content)

      def self.declaration(content)
        return unless (content = content.lstrip).start_with?("<?xml ")

        content.split("\n").first
      end

      attr_reader :doc, :decl

      def initialize(content, &block)
        instance_exec(&block) if block

        @doc ||= self.class.parse(content)
        @decl = self.class.declaration(content)
      end

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
