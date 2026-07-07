# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      # Element strategy for SVG style elements.
      # @api private
      module CSS
        # Converts a style node into unformatted Sevgi DSL lines.
        # @return [Array<String>] unformatted Ruby source lines
        def decompile(*)
          return [] unless (lines = css_lines)

          [
            "css({",
            *lines,
            "})",
            ""
          ]
        end

        private

        def css_lines
          return unless (hash = Css.to_h(node.content))

          hash
            .map do |selector, declarations|
              [
                "#{Ruby.literal(selector)}: {",
                *declarations.map { |key, value| "#{Css.to_key_value(key, value)}," },
                "},"
              ]
            end
            .flatten
        end
      end
    end
  end
end
