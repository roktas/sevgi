# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      module Root
        include Any

        def decompile(pres = [])
          lines = super
          return lines unless pres&.any?

          lines.unshift [
            "SVG.document preambles: [",
            *pres.map { "'#{it}'," },
            "]",
            "",
          ]
        end

        def element = "SVG"

        def attributes! = { **attributes, **namespaces }
      end
    end
  end
end
