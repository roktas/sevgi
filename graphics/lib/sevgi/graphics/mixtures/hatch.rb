# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for drawing geometry-derived hatch lines.
      module Hatch
        # Draws one or more geometry line-like objects into this element.
        # @param lines [Object, Array<Object>] drawable geometry objects
        # @param kwargs [Hash] SVG attributes passed to each draw call
        # @return [Array<Sevgi::Graphics::Element>] rendered line elements
        def Draw(lines, **kwargs)
          Array(lines).map { it.draw(self, **kwargs) }
        end

        # Draws hatch lines swept through a geometry element.
        # @param element [Sevgi::Geometry::Element::Lined] lined geometry element to sweep
        # @param angle [Numeric] hatch angle in degrees
        # @param step [Numeric] distance between hatch lines
        # @param initial [Sevgi::Geometry::Point, Array<Numeric>, nil] initial sweep point, or nil for element.position
        # @param kwargs [Hash] SVG attributes passed to each draw call
        # @return [Array<Sevgi::Graphics::Element>] rendered line elements
        # @raise [Sevgi::MissingComponentError] when sevgi/geometry is unavailable
        # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when element is not sweepable
        # @raise [Sevgi::Geometry::Error] when initial, angle, or step is invalid
        # @raise [Sevgi::Geometry::Operation::OperationError] when no hatch lines are found or iteration reaches the limit
        def Hatch(element, angle:, step:, initial: nil, **kwargs)
          begin
            require "sevgi/geometry"

          rescue ::LoadError => e
            raise unless e.path == "sevgi/geometry"

            MissingComponentError.("sevgi/geometry")
          end

          initial = element.position if initial.nil? && element.is_a?(Geometry::Element::Lined)
          Draw(Geometry::Operation.sweep!(element, initial:, angle:, step:), **kwargs)
        end
      end
    end
  end
end
