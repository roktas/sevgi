# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      # Default SVG document profile with XML preamble and SVG namespace.
      class Default < Base
        document(
          :default,
          attributes: {
            xmlns: "http://www.w3.org/2000/svg"
          },
          preambles: [
            "<?xml version=\"1.0\" standalone=\"no\"?>"
          ]
        )
      end
    end
  end
end
