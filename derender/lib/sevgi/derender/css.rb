# frozen_string_literal: true

require "css_parser"

module Sevgi
  module Derender
    class CSS
      class << self
        def call(hash)
          pre, post = {}, {}

          # These keys should come first.
          %w[ id inkscape:label class ].each { |key| pre[key] = hash.delete(key) if hash.key?(key) }
          # These keys should come last.
          %w[ style ].each { |key| post[key] = hash.delete(key) if hash.key?(key) }

          { **pre, **hash, **post }.map do |key, value|
            key = to_key(key) if key.is_a?(::String)

            if key == "style"
              "{ #{call(style_to_hash(value))} }"
            elsif value.is_a?(::String)
              to_value(value)
            elsif value.is_a?(::Hash)
              "{ #{call(value)} }"
            else
              value
            end => value

            key.match?(/\W/) ? "\"#{key}\": #{value}" : "#{key}: #{value}"
          end.join(", ")
        end

        private

          # Transforms the values of a style attribute to a hash
          # Example: "color: black; top: 10" => { color: black, top: 10 }
          def style_to_hash(string)
            parser = CssParser::Parser.new
            parser.load_string! "* { #{string} }"
            parser.to_h["all"]["*"]
          end

          def to_key(arg)   = arg

          def to_value(arg) = (arg.to_f.to_s == arg) || (arg.to_i.to_s == arg) ? arg : %("#{arg}")
      end

      attr_reader :css_string

      def initialize(css_string) = @css_string = css_string

      def to_h = parser.load_string!(css_string).to_h["all"]

      private

        def parser = @parser ||= CssParser::Parser.new
    end
  end
end
