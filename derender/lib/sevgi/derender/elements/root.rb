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
        def decompile(pres = [])
          lines = super
          return lines unless pres&.any?

          lines.unshift(
            [
              "SVG.document preambles: [",
              *pres.map { "#{Ruby.literal(it)}," },
              "]",
              ""
            ]
          )
        end

        # Returns the root DSL word.
        # @return [String]
        def element = "SVG"

      end
    end
  end
end
