# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Hatch
        def Draw(lines, **kwargs)
          Array(lines).map { it.draw(self, **kwargs) }
        end

        def Hatch(element, angle:, step:, initial: nil, **kwargs)
          require "sevgi/geometry"

          Draw(Geometry::Operation.sweep!(element, initial: initial || element.position, angle:, step:), **kwargs)
        rescue ::LoadError
          raise NoMethodError, "\"sevgi/geometry\" required"
        end
      end
    end
  end
end
