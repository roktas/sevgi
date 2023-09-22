# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Inkscape
        module InstanceMethods
          def layer(**, &block)
            g("inkscape:groupmode": "layer", "sodipodi:insensitive": "true", **, &block)
          end
        end
      end
    end
  end
end
