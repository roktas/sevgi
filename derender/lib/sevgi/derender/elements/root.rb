# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      # Element strategy for the SVG root element.
      # @api private
      module Root
        include Any

        # Converts the SVG root into unformatted Sevgi DSL lines.
        # @param pres [Array<String>] preamble XML lines
        # @return [Array<String>] unformatted Ruby source lines
        def decompile(pres = [], **)
          lines = super
          return lines unless pres&.any?

          lines[0] = document_call(lines.first)

          lines.unshift(preamble_lines(pres))
        end

        def document_call(line)
          return line.sub("SVG", "SVG document") if ["SVG", "SVG do"].include?(line)

          line.sub(/\ASVG /, "SVG document, ")
        end

        def preamble_lines(pres)
          ["document = SVG.Document preambles: [", *pres.map { "#{Ruby.literal(it)}," }, "]", ""]
        end

        private :document_call, :preamble_lines

        # Returns the root DSL word.
        # @return [String]
        def element = "SVG"

      end
    end
  end
end
