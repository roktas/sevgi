# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      # Base class for linear equations.
      class Linear < Equation
        # Non-axis-aligned linear equation in `y = slope * x + intercept` form.
        class Diagonal < Linear
          # Returns the line slope.
          # @return [Float]
          attr_reader :slope

          # Returns the y-intercept.
          # @return [Float]
          attr_reader :intercept

          # Creates a diagonal linear equation.
          # @param slope [Numeric] line slope
          # @param intercept [Numeric] y-intercept
          # @return [void]
          # @raise [Sevgi::Geometry::Error] when a coefficient is not a finite Numeric
          def initialize(slope:, intercept:)
            super()

            @slope = Real[:slope, slope]
            @intercept = Real[:intercept, intercept]
          end

          # Returns an equation rounded to precision.
          # @param precision [Integer, nil] decimal precision, or nil for the current function default
          # @return [Sevgi::Geometry::Equation::Linear::Diagonal]
          def approx(precision = nil)
            self.class.new(slope: F.approx(slope, precision), intercept: F.approx(intercept, precision))
          end

          # Reports strict equation equality.
          # @param other [Object] object to compare
          # @return [Boolean]
          def eql?(other) = self.class == other.class && [slope, intercept] == [other.slope, other.intercept]

          # Returns a hash compatible with strict equality.
          # @return [Integer]
          def hash = [self.class, slope, intercept].hash

          # Reports whether a point is on the left side of the line in screen coordinates.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def left?(point)
            point = Tuple[Point, point]

            F.gt?(point.y, y(point.x))
          end

          # Reports whether a point is on the line.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def on?(point)
            point = Tuple[Point, point]

            F.eq?(point.y, y(point.x))
          end

          # Reports whether a point is on the right side of the line in screen coordinates.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def right?(point)
            point = Tuple[Point, point]

            F.lt?(point.y, y(point.x))
          end

          # Returns a parallel equation shifted by a signed perpendicular offset.
          # @param distance [Numeric, nil] signed perpendicular offset
          # @param dx [Numeric, nil] explicit x translation
          # @param dy [Numeric, nil] explicit y translation
          # @return [Sevgi::Geometry::Equation::Linear::Diagonal]
          def shift(distance = nil, dx: nil, dy: nil)
            dx ||= 0.0
            dy ||= 0.0

            if distance
              dx += distance * F.sin(angle = F.atan(slope))
              dy -= distance * F.cos(angle)
            end

            Diagonal.new(slope:, intercept: intercept - (slope * dx) + dy)
          end

          # Formats the equation for display.
          # @return [String]
          def to_s
            strings = []

            strings << "#{F.approx(slope)} * x" unless F.zero?(slope)
            strings << F.approx(intercept).abs.to_s unless F.zero?(intercept)

            "Linear<y = #{strings.join(intercept.positive? ? " + " : " - ")}>"
          end

          # Evaluates x for a y coordinate.
          # @param y [Numeric] y coordinate
          # @return [Float]
          def x(y) = (y - intercept) / slope

          # Evaluates y for an x coordinate.
          # @param x [Numeric] x coordinate
          # @return [Float]
          def y(x) = (slope * x) + intercept

          alias == eql?
        end

        # Horizontal linear equation in `y = c` form.
        class Horizontal < Diagonal
          # Creates a horizontal equation.
          # @param c [Numeric] y coordinate
          # @return [void]
          # @raise [Sevgi::Geometry::Error] when c is not a finite Numeric
          def initialize(c) = super(slope: 0.0, intercept: c)

          # Returns an equation rounded to precision.
          # @param precision [Integer, nil] decimal precision, or nil for the current function default
          # @return [Sevgi::Geometry::Equation::Linear::Horizontal]
          def approx(precision = nil) = self.class.new(F.approx(intercept, precision))

          # Returns a parallel horizontal equation shifted by offsets.
          #
          # A positive signed distance shifts upward in screen coordinates.
          # @param distance [Numeric, nil] signed perpendicular offset
          # @param dx [Numeric, nil] accepted for signature compatibility and ignored
          # @param dy [Numeric, nil] explicit y translation
          # @return [Sevgi::Geometry::Equation::Linear::Horizontal]
          def shift(distance = nil, dx: nil, dy: nil)
            _dx = dx

            self.class.new(intercept + (dy || 0.0) - (distance || 0.0))
          end

          # Formats the equation for display.
          # @return [String]
          def to_s = "Linear<y = #{F.approx(intercept)}>"
        end

        # Vertical linear equation in `x = c` form.
        class Vertical < Linear
          # Creates a vertical equation.
          # @param c [Numeric] x coordinate
          # @return [void]
          # @raise [Sevgi::Geometry::Error] when c is not a finite Numeric
          def initialize(c)
            super()

            @x = Real[:x, c]
          end

          # Returns an equation rounded to precision.
          # @param precision [Integer, nil] decimal precision, or nil for the current function default
          # @return [Sevgi::Geometry::Equation::Linear::Vertical]
          def approx(precision = nil) = self.class.new(F.approx(x, precision))

          # Reports strict equation equality.
          # @param other [Object] object to compare
          # @return [Boolean]
          def eql?(other) = self.class == other.class && x == other.x

          # Returns a hash compatible with strict equality.
          # @return [Integer]
          def hash = [self.class, x].hash

          # Reports whether a point is on the left side of the line.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def left?(point)
            point = Tuple[Point, point]

            F.lt?(point.x, x(point.y))
          end

          # Reports whether a point is on the line.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def on?(point)
            point = Tuple[Point, point]

            F.eq?(point.x, x(point.y))
          end

          # Reports whether a point is on the right side of the line.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def right?(point)
            point = Tuple[Point, point]

            F.gt?(point.x, x(point.y))
          end

          # Returns a parallel vertical equation shifted by offsets.
          #
          # A positive signed distance shifts right in screen coordinates.
          # @param distance [Numeric, nil] signed perpendicular offset
          # @param dx [Numeric, nil] explicit x translation
          # @param dy [Numeric, nil] accepted for signature compatibility and ignored
          # @return [Sevgi::Geometry::Equation::Linear::Vertical]
          def shift(distance = nil, dx: nil, dy: nil)
            _dy = dy

            self.class.new(x + (distance || 0.0) + (dx || 0.0))
          end

          # Formats the equation for display.
          # @return [String]
          def to_s = "Linear<x = #{F.approx(x)}>"

          # Evaluates x for a y coordinate.
          # @param _ [Numeric, nil] ignored y coordinate
          # @return [Float]
          def x(_ = nil) = @x

          # Evaluates y for an x coordinate.
          # @param _ [Numeric, nil] ignored x coordinate
          # @return [Float] positive infinity because a vertical line has no single y
          def y(_ = nil) = ::Float::INFINITY

          alias == eql?
        end
      end
    end
  end
end
