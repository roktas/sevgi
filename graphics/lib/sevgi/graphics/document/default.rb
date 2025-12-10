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
            '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
          ]
      end
    end
  end
end
