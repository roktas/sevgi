# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      # SVG document profile intended for embedding in HTML.
      class HTML < Default
        document(
          :html,
          preambles: []
        )
      end
    end
  end
end
