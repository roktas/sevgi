#!/usr/bin/env ruby
# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      module CSS
        def compile(*)
          [
            "css({",
            *css_lines,
            "})",
            "",
          ]
        end

        private

          def css_lines
            hash = Derender::CSS.to_hash(node.content)

            hash.map do |selector, declarations|
              [
                "\"#{selector}\": {",
                *declarations.map { |key, value| "#{Attributes.to_key_value(key, value)}," },
                "},"
              ]
            end.flatten
          end
      end
    end
  end
end
