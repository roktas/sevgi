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
          return raw_style unless (lines = css_lines)

          [
            "css({",
            *lines,
            "}, #{css_attributes})",
            ""
          ]
        end

        private

        def css_attributes
          attributes = all_attributes
          source = Attributes.decompile(attributes)

          attributes.key?("type") ? source : [source, "type: nil"].reject(&:empty?).join(", ")
        end

        def css_lines
          return unless (hash = Css.rules(node.content))

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

        def raw_style
          arguments = ["Sevgi::Graphics::Content.cdata(#{Ruby.literal(node.content)})"]
          arguments << Attributes.decompile(all_attributes) if all_attributes.any?

          ["style #{arguments.join(", ")}", ""]
        end
      end
    end
  end
end
