# frozen_string_literal: true

require "css_parser"

module Sevgi
  module Derender
    class CSS
      def self.render(hash)
        [
          "{",
          hash.map do |selector, declarations|
            [
              "\"#{selector}\": {",
              *declarations.map { |key, value| "#{Attribute.pair(key, value)}," },
              "},"
            ]
          end,
          "}",
        ].flatten.join("\n")
      end

      attr_reader :css_string

      def initialize(css_string) = @css_string = css_string

      def to_h
        parser.load_string!(css_string)
        parser.to_h["all"]
      end

      private

        def parser = @parser ||= CssParser::Parser.new
    end
  end
end
