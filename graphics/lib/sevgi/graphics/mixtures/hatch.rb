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
        # @param element [Object] geometry element responding to position
        # @param angle [Numeric] hatch angle in degrees
        # @param step [Numeric] distance between hatch lines
        # @param initial [Object, nil] initial point for the sweep
        # @param kwargs [Hash] SVG attributes passed to each draw call
        # @return [Array<Sevgi::Graphics::Element>] rendered line elements
        # @raise [Sevgi::MissingComponentError] when sevgi/geometry is unavailable
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
