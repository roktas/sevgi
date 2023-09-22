# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Hatch
        module InstanceMethods
          def Draw(segments, **)
            segments.each { |segment| segment.draw(self, **) }
          end

          def Hatch(canvas, direction:, step:, **)
            Geometry::Operation.sweep!(rect = canvas.rect, initial: rect.position, direction:, step:).tap do |segments|
              Draw(segments, **)
            end
          end
        end
      end
    end
  end
end
