# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      class Linear < Equation
        class Diagonal < Linear
          attr_reader :slope, :intercept

          def initialize(slope:, intercept:)
            super()

            @slope = slope.to_f
            @intercept = intercept.to_f
          end

          def approx(precision = nil)
            self.class.new(slope: F.approx(slope, precision), intercept: F.approx(intercept, precision))
          end

          def eql?(other) = self.class == other.class && [slope, intercept] == [other.slope, other.intercept]

          def hash = [self.class, slope, intercept].hash

          def left?(point)
            point = Tuple[Point, point]

            F.gt?(point.y, y(point.x))
          end

          def on?(point)
            point = Tuple[Point, point]

            F.eq?(point.y, y(point.x))
          end

          def right?(point)
            point = Tuple[Point, point]

            F.lt?(point.y, y(point.x))
          end

          def shift(distance = nil, dx: nil, dy: nil)
            dx ||= 0.0
            dy ||= 0.0

            if distance
              dx += distance * F.sin(angle = F.atan(slope))
              dy -= distance * F.cos(angle)
            end

            Diagonal.new(slope:, intercept: intercept - (slope * dx) + dy)
          end

          def to_s
            strings = []

            strings << "#{F.approx(slope)} * x" unless F.zero?(slope)
            strings << F.approx(intercept).abs.to_s unless F.zero?(intercept)

            "Linear<y = #{strings.join(intercept.positive? ? " + " : " - ")}>"
          end

          def x(y) = (y - intercept) / slope

          def y(x) = (slope * x) + intercept

          alias == eql?
        end

        class Horizontal < Diagonal
          def initialize(c) = super(slope: 0.0, intercept: c)
        end

        class Vertical < Linear
          def initialize(c)
            super()

            @x = c
          end

          def left?(point)
            point = Tuple[Point, point]

            F.lt?(point.x, x(point.y))
          end

          def on?(point)
            point = Tuple[Point, point]

            F.eq?(point.x, x(point.y))
          end

          def right?(point)
            point = Tuple[Point, point]

            F.gt?(point.x, x(point.y))
          end

          def shift(distance = nil, dx: nil, dy: nil)
            _dy = dy

            self.class.new(x + (distance || 0.0) + (dx || 0.0))
          end

          def to_s = "Linear<x = #{F.approx(x)}>"

          def x(_ = nil) = @x

          def y(_ = nil) = ::Float::INFINITY
        end
      end
    end
  end
end
