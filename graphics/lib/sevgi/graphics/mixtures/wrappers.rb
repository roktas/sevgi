# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL wrappers for common SVG shapes and content patterns.
      module Wrappers
        # Builds a line path ending at an absolute point.
        # @param x2 [Numeric] ending x coordinate
        # @param y2 [Numeric] ending y coordinate
        # @param x1 [Numeric] starting x coordinate
        # @param y1 [Numeric] starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        def LineTo(x2:, y2:, x1: 0, y1: 0, **)
          path(d: "M #{x1} #{y1} L #{x2} #{y2}", **)
        end

        # Builds a horizontal line path ending at an absolute x coordinate.
        # @param x2 [Numeric] ending x coordinate
        # @param x1 [Numeric] starting x coordinate
        # @param y1 [Numeric] starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        def HLineTo(x2:, x1: 0, y1: 0, **)
          path(d: "M #{x1} #{y1} H #{x2}", **)
        end

        # Builds a titled SVG symbol.
        # @param name [String] human-readable symbol name
        # @param kwargs [Hash] symbol attributes
        # @return [Sevgi::Graphics::Element] symbol element
        def Symbol(name, **kwargs, &block)
          id = (words = name.split).map(&:downcase).join("-")
          title = words.map(&:capitalize).join(" ")

          symbol(id:, **kwargs) do
            title(title)
            Within(&block)
          end
        end

        # Builds a vertical line path ending at an absolute y coordinate.
        # @param y2 [Numeric] ending y coordinate
        # @param x1 [Numeric] starting x coordinate
        # @param y1 [Numeric] starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        def VLineTo(y2:, x1: 0, y1: 0, **)
          path(d: "M #{x1} #{y1} V #{y2}", **)
        end

        # Builds a relative line path from angle and length.
        # @param angle [Numeric] angle in degrees
        # @param length [Numeric] line length
        # @param x [Numeric] starting x coordinate
        # @param y [Numeric] starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        def LineBy(angle:, length:, x: 0, y: 0, **)
          dx = length * ::Math.cos(angle.to_f / 180 * ::Math::PI)
          dy = length * ::Math.sin(angle.to_f / 180 * ::Math::PI)
          path(d: "M #{x} #{y} l #{dx} #{dy}", **)
        end

        # Builds a style element with CSS content.
        # @param hash [Hash, nil] CSS rules
        # @param attributes [Hash] style attributes or CSS rules when hash is nil
        # @return [Sevgi::Graphics::Element] style element
        # @raise [Sevgi::ArgumentError] when CSS rules are malformed, cyclic, cannot be stringified, or contain invalid
        #   encoding or illegal XML 1.0 characters
        def css(hash = nil, **attributes)
          hash, attributes = attributes, {} unless hash

          style(Content.css(hash), type: "text/css", **attributes)
        end

        # Builds a relative horizontal line path.
        # @param length [Numeric] line length
        # @param x [Numeric] starting x coordinate
        # @param y [Numeric] starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        def HLineBy(length:, x: 0, y: 0, **)
          path(d: "M #{x} #{y} h #{length}", **)
        end

        # Builds a square rect.
        # @param length [Numeric] side length
        # @return [Sevgi::Graphics::Element] rect element
        def square(length:, **)
          rect(width: length, height: length, **)
        end

        # Builds a relative vertical line path.
        # @param length [Numeric] line length
        # @param x [Numeric] starting x coordinate
        # @param y [Numeric] starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        def VLineBy(length:, x: 0, y: 0, **)
          path(d: "M #{x} #{y} v #{length}", **)
        end
      end
    end
  end
end
