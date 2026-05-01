# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Transform
        def Align(position, inner:, outer:)
          return self unless position && inner && outer

          case position.to_sym
          when :center then Translate((outer.width - inner.width) / 2.0, (outer.height - inner.height) / 2.0)
          else              ArgumentError.("Unsupported alignment: #{position}")
          end
        end

        def Flip
          tap do
            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "scale(-1, 1) scale(1, 1)"
          end
        end

        def FlipX
          tap do
            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "scale(-1, 1)"
          end
        end

        def FlipY
          tap do
            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "scale(1, -11)"
          end
        end

        def Matrix(*values)
          tap do
            ArgumentError.("Incorrect transform matrix (six values required): #{values}") if values.size != 6

            next if values.map(&:to_f).all? { it == 0.0 }

            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "matrix(#{values.join(" ")})"
          end
        end

        def Rotate(a, *origin)
          tap do
            ArgumentError.("Incorrect origin (two coordinates required): #{origin}") if !origin.empty? && origin.size != 2

            next if a.to_f == 0.0

            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "rotate(#{[ a, *origin ].join(", ")})"
          end
        end

        def Rotate90(...) = Rotate(90, ...)

        def Rotate09(...) = Rotate(-90, ...)

        def Scale(x, y = nil)
          tap do
            next if x.to_f == 0.0 && (y.nil? || y.to_f == 0.0)

            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "scale(#{(y ? [ x, y ] : [ x ]).join(", ")})"
          end
        end

        def Scale!(...)
          Scale(...).tap do
            attributes[:"vector-effect"] = "non-scaling-stroke" unless attributes[:"vector-effect"]
          end
        end

        def Skew(ax, ay)
          Matrix(1.0, ::Math.tan(ay / 180.0 * ::Math::PI), ::Math.tan(ax / 180.0 * ::Math::PI), 1.0, 0.0, 0.0)
        end

        def SkewX(a)
          tap do
            next if a.to_f == 0.0

            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "skewX(#{a})"
          end
        end

        def SkewY(a)
          tap do
            next if a.to_f == 0.0

            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "skewY(#{a})"
          end
        end

        def Translate(x, y = nil)
          tap do
            next if x.to_f == 0.0 && (y.nil? || y.to_f == 0.0)

            attributes[:"transform#{ATTRIBUTE_UPDATE_SUFFIX}"] = "translate(#{(y ? [ x, y ] : [ x ]).join(" ")})"
          end
        end
      end
    end
  end
end
