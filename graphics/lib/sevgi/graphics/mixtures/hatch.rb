# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for drawing geometry values and geometry-derived hatch lines.
      #
      # `Draw` delegates to each geometry object's drawing protocol. `Hatch`
      # first sweeps interior spans through a closed lined element, then draws
      # them. Its `angle` describes line direction; `step` is perpendicular
      # spacing. The default initial line passes through `element.position`.
      # The built-in `:inkscape` document profile includes this mixture;
      # `:minimal`, `:default`, and `:html` do not.
      #
      # Hatch materializes separate finite SVG path elements. When only a repeated visual fill matters, use an SVG
      # pattern and leave repetition and clipping to the renderer instead of computing line geometry.
      # @example Add geometry drawing to a scoped custom profile
      #   profile = Class.new(Sevgi::Graphics::Document::Base)
      #   Sevgi::Graphics::Mixtures.mixin(:Hatch, profile)
      #   region = Sevgi::Geometry::Rect[24, 12]
      #   Sevgi::Graphics.SVG(profile) do
      #     Draw region.lines, stroke: "silver"
      #     Hatch region, angle: 30, step: 3, stroke: "black"
      #   end.Render
      # @see Sevgi::Geometry::Operation.sweep
      # @see https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/pattern SVG pattern element
      module Hatch
        # Draws one or more geometry line-like objects into this element.
        # @example Draw geometry lines into a library-built document
        #   lines = [
        #     Sevgi::Geometry::Line.([0, 0], [20, 0]),
        #     Sevgi::Geometry::Line.([0, 5], [20, 5])
        #   ]
        #   drawing = Sevgi::Graphics.SVG(:inkscape) { Draw lines, stroke: "silver" }
        #   drawing.Render
        # @param lines [#draw, Array<#draw>] drawable geometry objects
        # @param kwargs [Hash] SVG attributes passed to each draw call
        # @return [Array<Sevgi::Graphics::Element>] rendered SVG elements
        def Draw(lines, **kwargs)
          Array(lines).map { it.draw(self, **kwargs) }
        end

        # Draws hatch lines swept through a geometry element.
        # @example Hatch a closed geometry shape
        #   region = Sevgi::Geometry::Rect[24, 12, position: [2, 2]]
        #   drawing = Sevgi::Graphics.SVG(:inkscape) do
        #     Hatch region, angle: 30, step: 3, stroke: "black"
        #   end
        #   drawing.Render
        # @example Control the first sweep line explicitly
        #   region = Sevgi::Geometry::Rect[24, 12, position: [2, 2]]
        #   Sevgi::Graphics.SVG(:inkscape) do
        #     Hatch region, initial: [2, 8], angle: 0, step: 3
        #   end
        # @param element [Sevgi::Geometry::Element::Lined] lined geometry element to sweep
        # @param angle [Numeric] hatch angle in degrees
        # @param step [Numeric] distance between hatch lines
        # @param initial [Sevgi::Geometry::Point, Array<Numeric>, nil] initial sweep point, or nil for element.position
        # @param kwargs [Hash] SVG attributes passed to each draw call
        # @return [Array<Sevgi::Graphics::Element>] rendered hatch path elements
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
