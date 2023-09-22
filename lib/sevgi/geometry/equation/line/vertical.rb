# frozen_string_literal: true

module Sevgi
  module Geometry
    module Equation
      module Line
        class Vertical
          def initialize(c)
            @x = c
          end

          def intersection(other)
            case other
            when Diagonal, Horizontal then x, y = self.x, other.y(self.x)
            when Vertical             then x, y = ::Float::INFINITY, ::Float::INFINITY
            end

            Point[x, y]
          end

          def left?(point)
            F.lt?(point.x, x(point.y))
          end

          def onto?(point)
            F.eq?(point.x, x(point.y))
          end

          def right?(point)
            F.gt?(point.x, x(point.y))
          end

          def shift(distance = nil, dx: nil, dy: nil)
            self.class.new(x + (distance || 0.0) + (dx || 0.0))
          end

          def to_s
            "L<x = #{F.approx(x)}>"
          end

          def x(_ = nil)
            @x
          end

          def y(_ = nil)
            ::Float::INFINITY
          end
        end
      end
    end
  end
end
