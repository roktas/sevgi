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

        def Matrix(*values)
          tap do
            ArgumentError.("Incorrect transform matrix (six values required): #{values}") if values.size != 6

            next if values.map(&:to_f).all? { it == 0.0 }

            attributes[:"transform+"] = "matrix(#{values.join(" ")})"
          end
        end

        def Rotate(a, *origin)
          tap do
            ArgumentError.("Incorrect origin (two coordinates required): #{origin}") if !origin.empty? && origin.size != 2

            next if a.to_f == 0.0

            attributes[:"transform+"] = "rotate(#{[ a, *origin ].join(", ")})"
          end
        end

        def Scale(x, y = nil)
          tap do
            next if x.to_f == 0.0 && (y.nil? || y.to_f == 0.0)

            attributes[:"transform+"] = "scale(#{(y ? [ x, y ] : [ x ]).join(", ")})"
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

            attributes[:"transform+"] = "skewX(#{a})"
          end
        end

        def SkewY(a)
          tap do
            next if a.to_f == 0.0

            attributes[:"transform+"] = "skewY(#{a})"
          end
        end

        def Translate(x, y = nil)
          tap do
            next if x.to_f == 0.0 && (y.nil? || y.to_f == 0.0)

            attributes[:"transform+"] = "translate(#{(y ? [ x, y ] : [ x ]).join(" ")})"
          end
        end
      end
    end
  end
end
