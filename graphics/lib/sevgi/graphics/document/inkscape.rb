# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      class Inkscape < Default
        document :inkscape,
          attributes: {
            "xmlns:_":         "http://sevgi.roktas.dev",
            "xmlns:inkscape":  "http://www.inkscape.org/namespaces/inkscape",
            "xmlns:sodipodi":  "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",

            "shape-rendering": "crispEdges"
          }

        mixture :Inkscape
        mixture :RDF
      end
    end
  end
end
