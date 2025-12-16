#!/usr/bin/env ruby
# frozen_string_literal: true

require "css_parser"

module Sevgi
  module Derender
    module Elements
      module CSS
        def compile(*)
          [
            "css({",
            *css_lines,
            "})",
          ]
        end

        private

          def css_lines
            hash = css_to_hash(node.content)

            hash.map do |selector, declarations|
              [
                "\"#{selector}\": {",
                *declarations.map { |key, value| "#{Attributes.to_key_value(key, value)}," },
                "},"
              ]
            end.flatten
          end

          def css_to_hash(css_string)
            parser = CssParser::Parser.new
            parser.load_string!(css_string)
            parser.to_h["all"]
          end
      end
    end
  end
end
