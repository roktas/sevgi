# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Hatch
        module InstanceMethods
          def Draw(segments, **kwargs)
            segments.each { |segment| segment.draw(self, **kwargs) }
          end

          def Hatch(canvas, direction:, step:, **kwargs)
            Geometry::Operation.sweep!(rect = canvas.rect, initial: rect.position, direction:, step:).tap do |segments|
              Draw(segments, **kwargs)
            end
          end
        end
      end
    end
  end
end
