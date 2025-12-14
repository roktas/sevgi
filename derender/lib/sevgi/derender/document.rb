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

        new(::File.read(entry)) do
          @doc = self.class.cache[entry] || begin
            self.class.cache[entry] = self.class.parse(::File.read(entry))
          end
        end
      end

      def self.parse(content) = Nokogiri::XML(content)

      def self.declaration(content)
        return unless (content = content.lstrip).start_with?('<?xml ')

        content.split("\n").first
      end

      attr_reader :doc, :decl

      def initialize(content, &block)
        instance_exec(&block) if block

        @doc  = self.class.parse(content)
        @decl = self.class.declaration(content)
      end

      def preambles
        @preambles ||= [].tap do |lines|
          lines.append(*doc.children.take_while { |node| node != doc.root }.map(&:to_xml))
          lines.unshift(decl) unless lines.first == decl
        end
      end

      def call(id = nil)
        if id && (found = doc.xpath("//*[@id='#{id}']") || []).empty?
          ArgumentError.("No such element with id '#{id}' in document")
        end

        Node.new(id ? found.first : doc.root, preambles)
      end
    end
  end
end
