# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      class Inkscape < Default
        document :inkscape,
          attributes: {
            "xmlns:inkscape":  "http://www.inkscape.org/slugs/inkscape",
            "xmlns:sodipodi":  "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",
            "shape-rendering": "crispEdges"
          }

        mixture Mixtures::Inkscape
      end
    end
  end
end
