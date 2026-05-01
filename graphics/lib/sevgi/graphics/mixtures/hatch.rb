# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Hatch
        def Draw(lines, **kwargs)
          Array(lines).map { it.draw(self, **kwargs) }
        end

        def Hatch(element, initial: nil, direction:, step:, **kwargs) # TODO: angle vs direction
          Draw(Geometry::Operation.sweep!(element, initial: initial || element.position, direction:, step:), **kwargs)
        end
      end
    end
  end
end
