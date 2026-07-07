# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Hatch
        def Draw(lines, **kwargs)
          Array(lines).map { it.draw(self, **kwargs) }
        end

        def Hatch(element, angle:, step:, initial: nil, **kwargs)
          begin
            require "sevgi/geometry"

          rescue ::LoadError => e
            raise unless e.path == "sevgi/geometry"

            MissingComponentError.("sevgi/geometry")
          end

          Draw(Geometry::Operation.sweep!(element, initial: initial || element.position, angle:, step:), **kwargs)
        end
      end
    end
  end
end
