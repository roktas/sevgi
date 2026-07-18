# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL wrappers for common SVG shapes and content patterns.
      module Wrappers
        # Builds a line path ending at an absolute point.
        # @example Render a rational coordinate as an SVG number
        #   Sevgi::Graphics.SVG { LineTo(x2: Rational(1, 2), y2: 1) }
        # @param x2 [Numeric] finite ending x coordinate
        # @param y2 [Numeric] finite ending y coordinate
        # @param x1 [Numeric] finite starting x coordinate
        # @param y1 [Numeric] finite starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        # @raise [Sevgi::ArgumentError] when a coordinate is not a finite real number
        def LineTo(x2:, y2:, x1: 0, y1: 0, **)
          x1 = Scalar.number(x1, context: "absolute line", field: :x1)
          y1 = Scalar.number(y1, context: "absolute line", field: :y1)
          x2 = Scalar.number(x2, context: "absolute line", field: :x2)
          y2 = Scalar.number(y2, context: "absolute line", field: :y2)

          path(d: "M #{x1} #{y1} L #{x2} #{y2}", **)
        end

        # Builds a horizontal line path ending at an absolute x coordinate.
        # @param x2 [Numeric] finite ending x coordinate
        # @param x1 [Numeric] finite starting x coordinate
        # @param y1 [Numeric] finite starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        # @raise [Sevgi::ArgumentError] when a coordinate is not a finite real number
        def HLineTo(x2:, x1: 0, y1: 0, **)
          x1 = Scalar.number(x1, context: "horizontal line", field: :x1)
          y1 = Scalar.number(y1, context: "horizontal line", field: :y1)
          x2 = Scalar.number(x2, context: "horizontal line", field: :x2)

          path(d: "M #{x1} #{y1} H #{x2}", **)
        end

        # Builds a titled SVG symbol.
        # @param name [String] human-readable symbol name
        # @param kwargs [Hash] symbol attributes
        # @yield evaluates the drawing DSL in the symbol element
        # @yieldreturn [Object] ignored block result
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
        # @param y2 [Numeric] finite ending y coordinate
        # @param x1 [Numeric] finite starting x coordinate
        # @param y1 [Numeric] finite starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        # @raise [Sevgi::ArgumentError] when a coordinate is not a finite real number
        def VLineTo(y2:, x1: 0, y1: 0, **)
          x1 = Scalar.number(x1, context: "vertical line", field: :x1)
          y1 = Scalar.number(y1, context: "vertical line", field: :y1)
          y2 = Scalar.number(y2, context: "vertical line", field: :y2)

          path(d: "M #{x1} #{y1} V #{y2}", **)
        end

        # Builds a relative line path from angle and length.
        # @param angle [Numeric] finite angle in degrees, normalized before calculation
        # @param length [Numeric] finite line length, normalized before calculation
        # @param x [Numeric] finite starting x coordinate, normalized to an SVG number
        # @param y [Numeric] finite starting y coordinate, normalized to an SVG number
        # @return [Sevgi::Graphics::Element] path element
        # @raise [Sevgi::ArgumentError] when an operand is not a finite real number
        def LineBy(angle:, length:, x: 0, y: 0, **)
          angle, length, x, y = Scalar.numbers([angle, length, x, y], context: "relative line")
          dx, dy = Scalar.numbers(
            [
              length * ::Math.cos(angle.to_f / 180 * ::Math::PI),
              length * ::Math.sin(angle.to_f / 180 * ::Math::PI)
            ],
            context: "relative line result"
          )

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
        # @param length [Numeric] finite line length
        # @param x [Numeric] finite starting x coordinate
        # @param y [Numeric] finite starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        # @raise [Sevgi::ArgumentError] when an operand is not a finite real number
        def HLineBy(length:, x: 0, y: 0, **)
          length = Scalar.number(length, context: "horizontal line", field: :length)
          x = Scalar.number(x, context: "horizontal line", field: :x)
          y = Scalar.number(y, context: "horizontal line", field: :y)

          path(d: "M #{x} #{y} h #{length}", **)
        end

        # Builds a square rect.
        # @param length [Numeric] finite side length
        # @return [Sevgi::Graphics::Element] rect element
        # @raise [Sevgi::ArgumentError] when length is not a finite real number
        def square(length:, **)
          length = Scalar.number(length, context: "square", field: :length)

          rect(width: length, height: length, **)
        end

        # Builds a relative vertical line path.
        # @param length [Numeric] finite line length
        # @param x [Numeric] finite starting x coordinate
        # @param y [Numeric] finite starting y coordinate
        # @return [Sevgi::Graphics::Element] path element
        # @raise [Sevgi::ArgumentError] when an operand is not a finite real number
        def VLineBy(length:, x: 0, y: 0, **)
          length = Scalar.number(length, context: "vertical line", field: :length)
          x = Scalar.number(x, context: "vertical line", field: :x)
          y = Scalar.number(y, context: "vertical line", field: :y)

          path(d: "M #{x} #{y} v #{length}", **)
        end
      end
    end
  end
end
