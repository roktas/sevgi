# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      class Default < Minimal
        document :default,
          attributes: {
            "xmlns": "http://www.w3.org/2000/svg"
          },
          preambles:  [
            '<?xml version="1.0" standalone="no"?>',
          ]
      end
    end
  end
end
