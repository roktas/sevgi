# frozen_string_literal: true

require "css_parser"

module Sevgi
  module Derender
    class CSS
      class << self
        def render(hash)
          pre, post = {}, {}

          %w[ id inkscape:label ].each do |key|
            pre[key] = hash.delete(key) if hash.key?(key)
          end

          %w[ style ].each do |key|
            post[key] = hash.delete(key) if hash.key?(key)
          end

          { **pre, **hash, **post }.map do |key, value|
            key = to_key(key) if key.is_a? String

            if key == "style"
              value = "{ #{render(style_to_hash(value))} }"
            elsif value.is_a? String
              value = to_value(value)
            end

            key.match?(/[^a-zA-Z0-9_]/) ? "\"#{key}\": #{value}" : "#{key}: #{value}"
          end.join(", ")
        end

        private

          # Transforms the values of a style attribute to a hash
          # Example: "color: black; top: 10" => { color: black, top: 10 }
          def style_to_hash(string)
            parser = CssParser::Parser.new
            parser.load_string! "sevgi { #{string} }"
            parser.to_h["all"]["sevgi"]
          end

          def to_key(string)   = string

          def to_value(string) = (string.to_f.to_s == string) || (string.to_i.to_s == string) ? string : %( "#{string}" )
      end

      attr_reader :css_string

      def initialize(css_string) = @css_string = css_string

      def to_h = parser.load_string!(css_string).to_h["all"]

      private

        def parser = @parser ||= CssParser::Parser.new
    end
  end
end
