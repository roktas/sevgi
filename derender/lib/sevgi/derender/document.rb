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

      attr_reader :doc

      def initialize(content, &block)
        instance_exec(&block) if block
        @doc ||= self.class.parse(content)
      end

      def call(id) = Node.new(doc.xpath("//*[@id='#{id}']").first)
    end
  end
end
