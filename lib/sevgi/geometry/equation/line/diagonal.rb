# frozen_string_literal: true

module Sevgi
  module Geometry
    module Equation
      module Line
        class Diagonal
          attr_reader :slope, :intercept, :direction

          def initialize(slope:, intercept:)
            @slope     = slope.to_f
            @intercept = intercept.to_f
            @direction = F.angles(@slope)
          end

          def approx(precision = nil)
            self.class.new(slope: F.approx(slope, precision), intercept: F.approx(intercept, precision))
          end

          def eql?(other)
            self.class == other.class && [ slope, intercept ] == [ other.slope, other.intercept ]
          end

          alias_method :==, :eql?

          def hash
            [ self.class, slope, intercept ].hash
          end

          def intersection(other)
            case other
            when Diagonal   then y = y(x = (other.intercept - intercept) / (slope - other.slope))
            when Horizontal then x = x(y = other.y)
            when Vertical   then y = y(x = other.x)
            end

            Point[x, y]
          end

          def left?(point)
            F.gt?(point.y, y(point.x))
          end

          def onto?(point)
            F.eq?(point.y, y(point.x))
          end

          def right?(point)
            F.lt?(point.y, y(point.x))
          end

          def shift(distance = nil, dx: nil, dy: nil)
            dx ||= 0.0
            dy ||= 0.0

            if distance
              dx += F.rx(distance, direction)
              dy -= F.ry(distance, direction)
            end

            Diagonal.new(slope:, intercept: intercept - slope * dx + dy)
          end

          def to_s
            strings = []

            strings << "#{F.approx(slope)} * x"     if F.nonzero?(slope)
            strings << F.approx(intercept).abs.to_s if F.nonzero?(intercept)

            "L<y = #{strings.join(intercept.positive? ? " + " : " - ")}>"
          end

          def x(y)
            (y - intercept) / slope
          end

          def y(x)
            (slope * x) + intercept
          end
        end
      end
    end
  end
end
