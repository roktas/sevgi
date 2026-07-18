# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for SVG transform attributes.
      #
      # Transform calls are appended in call order and return the element, so they can be composed.
      # @example Compose transforms on one element
      #   Sevgi::Graphics.SVG(:minimal) do
      #     rect(width: 8, height: 4).Translate(12, 6).Rotate(15, 4, 2)
      #   end
      module Transform
        # Aligns an inner box inside an outer box.
        # @param position [Symbol, String, nil] alignment name
        # @param inner [#width, #height, nil] inner box
        # @param outer [#width, #height, nil] outer box
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when alignment is unsupported
        # @raise [Sevgi::ArgumentError] when a box dimension is not a finite real number
        def Align(position, inner:, outer:)
          return self unless position && inner && outer

          case position.to_sym
          when :center
            dimensions = [inner.width, inner.height, outer.width, outer.height]
            iw, ih, ow, oh = dimensions.map { Scalar.number(it, context: "alignment", field: :dimension) }
            Translate((ow - iw) / 2.0, (oh - ih) / 2.0)
          else
            ArgumentError.("Unsupported alignment: #{position}")
          end
        end

        # Appends a scale(-1, -1) transform.
        # @return [Sevgi::Graphics::Element] self
        def Flip
          tap do
            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "scale(-1, -1)"
          end
        end

        # Appends a horizontal flip transform.
        # @return [Sevgi::Graphics::Element] self
        def FlipX
          tap do
            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "scale(-1, 1)"
          end
        end

        # Appends a vertical flip transform.
        # @return [Sevgi::Graphics::Element] self
        def FlipY
          tap do
            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "scale(1, -1)"
          end
        end

        # Appends a six-value SVG matrix transform.
        # @param values [Array<Numeric>] finite matrix values, normalized to SVG numbers
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when six finite real values are not supplied
        def Matrix(*values)
          tap do
            ArgumentError.("Incorrect transform matrix (six values required): #{values}") if values.size != 6
            values = Scalar.numbers(values, context: "matrix")

            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "matrix(#{values.join(" ")})"
          end
        end

        # Appends an SVG rotate transform.
        # @param a [Numeric] finite angle in degrees, normalized to an SVG number
        # @param origin [Array<Numeric>] optional finite x and y origin, normalized to SVG numbers
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when angle or origin is not finite real, or origin is not two coordinates
        def Rotate(a, *origin)
          tap do
            if !origin.empty? && origin.size != 2
              ArgumentError.("Incorrect origin (two coordinates required): #{origin}")
            end

            angle = Scalar.number(a, context: "rotation", field: :angle)
            origin = Scalar.numbers(origin, context: "rotation")

            next if angle.zero?

            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "rotate(#{[angle, *origin].join(", ")})"
          end
        end

        # @overload RotateRight(*origin)
        #   Appends a 90-degree SVG rotate transform.
        #   @param origin [Array<Numeric>] optional x and y origin
        #   @return [Sevgi::Graphics::Element] self
        def RotateRight(...) = Rotate(90, ...)

        # @overload RotateLeft(*origin)
        #   Appends a -90-degree SVG rotate transform.
        #   @param origin [Array<Numeric>] optional x and y origin
        #   @return [Sevgi::Graphics::Element] self
        def RotateLeft(...) = Rotate(-90, ...)

        # Appends an SVG scale transform.
        # @param x [Numeric] finite x scale, or uniform scale when y is nil
        # @param y [Numeric, nil] finite y scale
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when a scale is not a finite real number
        def Scale(x, y = nil)
          tap do
            x = Scalar.number(x, context: "scale", field: :x)
            y = Scalar.number(y, context: "scale", field: :y) unless y.nil?
            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "scale(#{(y.nil? ? [x] : [x, y]).join(", ")})"
          end
        end

        # Appends a skew transform through an SVG matrix.
        # @param ax [Numeric] finite x skew angle in degrees, normalized before calculation
        # @param ay [Numeric] finite y skew angle in degrees, normalized before calculation
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when an angle is not a finite real number
        def Skew(ax, ay)
          ax = Scalar.number(ax, context: "skew", field: :x)
          ay = Scalar.number(ay, context: "skew", field: :y)
          Matrix(1.0, ::Math.tan(ay / 180.0 * ::Math::PI), ::Math.tan(ax / 180.0 * ::Math::PI), 1.0, 0.0, 0.0)
        end

        # Appends an SVG skewX transform.
        # @param a [Numeric] finite angle in degrees, normalized to an SVG number
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when angle is not a finite real number
        def SkewX(a)
          tap do
            angle = Scalar.number(a, context: "skew", field: :x)
            next if angle.zero?

            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "skewX(#{angle})"
          end
        end

        # Appends an SVG skewY transform.
        # @param a [Numeric] finite angle in degrees, normalized to an SVG number
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when angle is not a finite real number
        def SkewY(a)
          tap do
            angle = Scalar.number(a, context: "skew", field: :y)
            next if angle.zero?

            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "skewY(#{angle})"
          end
        end

        # Appends an SVG translate transform. One argument translates only the x axis.
        # @param x [Numeric] finite x translation, normalized to an SVG number
        # @param y [Numeric, nil] finite y translation, normalized to an SVG number
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when a coordinate is not a finite real number
        def Translate(x, y = nil)
          tap do
            dx = Scalar.number(x, context: "translation", field: :x)
            dy = Scalar.number(y, context: "translation", field: :y) unless y.nil?
            next if dx.zero? && (dy.nil? || dy.zero?)

            attributes[:"transform#{Attributes::UPDATE_SUFFIX}"] = "translate(#{(dy.nil? ? [dx] : [dx, dy]).join(" ")})"
          end
        end

        # Appends an x-axis SVG translate transform.
        # @param x [Numeric] finite x translation
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when x is not a finite real number
        # @see #Translate
        def TranslateX(x) = Translate(x)

        # Appends a y-axis SVG translate transform.
        # @param y [Numeric] finite y translation
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when y is not a finite real number
        # @see #Translate
        def TranslateY(y) = Translate(0, y)
      end
    end
  end
end
