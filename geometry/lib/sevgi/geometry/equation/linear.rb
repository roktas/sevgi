# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      # Base class for unoriented linear equations.
      #
      # An equation has no ordered endpoints, so it does not define intrinsic left and right sides. Signed shifts use a
      # canonical direction only to select a normal: increasing x for non-vertical equations and increasing y for
      # vertical equations. Positive distance moves to screen-left of that canonical direction.
      class Linear < Equation
        def shift_values(distance, dx, dy)
          [[:distance, distance], [:dx, dx], [:dy, dy]].map do |field, value|
            value.nil? ? 0.0 : Real[field, value]
          end
        end

        private :shift_values

        # Shared behavior for equations that map x coordinates to y coordinates.
        # @api private
        module Nonvertical
          # Reports strict equality for two nonvertical equations.
          # @param equation [Sevgi::Geometry::Equation::Linear] equation to compare
          # @param other [Object] comparison target
          # @return [Boolean]
          def self.equal?(equation, other)
            equation.class == other.class && [equation.slope, equation.intercept] == [other.slope, other.intercept]
          end

          # Returns a strict-equality hash for a nonvertical equation.
          # @param equation [Sevgi::Geometry::Equation::Linear] equation to hash
          # @return [Integer]
          def self.hash(equation) = [equation.class, equation.slope, equation.intercept].hash

          # Reports whether a point is on a nonvertical equation.
          # @param equation [Sevgi::Geometry::Equation::Linear] equation to test
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def self.on?(equation, point)
            point = Tuple[Point, point]

            F.eq?(point.y, y(equation, point.x))
          end

          # Evaluates a nonvertical equation at an x coordinate.
          # @param equation [Sevgi::Geometry::Equation::Linear] equation to evaluate
          # @param x [Numeric] x coordinate
          # @return [Float]
          # @raise [Sevgi::Geometry::Error] when x is not a finite real number
          def self.y(equation, x) = (equation.slope * Real[:x, x]) + equation.intercept
        end

        private_constant :Nonvertical

        # Non-axis-aligned linear equation in `y = slope * x + intercept` form.
        class Diagonal < Linear
          public_class_method :new

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
          # @raise [Sevgi::Geometry::Error] when a coefficient is not finite Numeric or slope is zero
          def initialize(slope:, intercept:)
            super()

            @slope = Real[:slope, slope]
            @intercept = Real[:intercept, intercept]
            Error.("A diagonal equation requires a non-zero slope") if @slope.zero?
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
          def eql?(other) = Nonvertical.equal?(self, other)

          # Returns a hash compatible with strict equality.
          # @return [Integer]
          def hash = Nonvertical.hash(self)

          # Reports whether a point is on the line.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def on?(point) = Nonvertical.on?(self, point)

          # Returns a parallel equation shifted by a signed perpendicular offset.
          # Positive distance moves to screen-left of the equation's canonical increasing-x direction.
          # @param distance [Numeric, nil] signed perpendicular offset
          # @param dx [Numeric, nil] explicit x translation
          # @param dy [Numeric, nil] explicit y translation
          # @return [Sevgi::Geometry::Equation::Linear::Diagonal]
          # @raise [Sevgi::Geometry::Error] when an operand is not a finite real number
          def shift(distance = nil, dx: nil, dy: nil)
            distance, dx, dy = shift_values(distance, dx, dy)
            angle = F.atan(slope)
            dx += distance * F.sin(angle)
            dy -= distance * F.cos(angle)

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
          # @raise [Sevgi::Geometry::Error] when y is not a finite real number
          def x(y) = (Real[:y, y] - intercept) / slope

          # Evaluates y for an x coordinate.
          # @param x [Numeric] x coordinate
          # @return [Float]
          # @raise [Sevgi::Geometry::Error] when x is not a finite real number
          def y(x) = Nonvertical.y(self, x)

          alias == eql?
        end

        # Horizontal linear equation in `y = c` form.
        class Horizontal < Linear
          public_class_method :new

          # Returns the zero line slope.
          # @return [Float]
          attr_reader :slope

          # Returns the y coordinate.
          # @return [Float]
          attr_reader :intercept

          # Creates a horizontal equation.
          # @param c [Numeric] y coordinate
          # @return [void]
          # @raise [Sevgi::Geometry::Error] when c is not a finite Numeric
          def initialize(c)
            super()

            @slope = 0.0
            @intercept = Real[:y, c]
          end

          # Returns an equation rounded to precision.
          # @param precision [Integer, nil] decimal precision, or nil for the current function default
          # @return [Sevgi::Geometry::Equation::Linear::Horizontal]
          def approx(precision = nil) = self.class.new(F.approx(intercept, precision))

          # Reports strict equation equality.
          # @param other [Object] object to compare
          # @return [Boolean]
          def eql?(other) = Nonvertical.equal?(self, other)

          # Returns a hash compatible with strict equality.
          # @return [Integer]
          def hash = Nonvertical.hash(self)

          # Reports whether a point is on the line.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def on?(point) = Nonvertical.on?(self, point)

          # Returns a parallel horizontal equation shifted by offsets.
          #
          # A positive signed distance shifts upward in screen coordinates.
          # @param distance [Numeric, nil] signed perpendicular offset
          # @param dx [Numeric, nil] accepted for signature compatibility and ignored
          # @param dy [Numeric, nil] explicit y translation
          # @return [Sevgi::Geometry::Equation::Linear::Horizontal]
          # @raise [Sevgi::Geometry::Error] when an operand is not a finite real number
          def shift(distance = nil, dx: nil, dy: nil)
            distance, _dx, dy = shift_values(distance, dx, dy)

            self.class.new(intercept + dy - distance)
          end

          # Rejects x lookup because a horizontal equation does not determine one x coordinate.
          # @param _y [Numeric] y coordinate
          # @return [void]
          # @raise [Sevgi::Geometry::Error] always, because x is indeterminate
          def x(_y) = Error.("x is indeterminate for a horizontal equation")

          # Formats the equation for display.
          # @return [String]
          def to_s = "Linear<y = #{F.approx(intercept)}>"

          # Evaluates y for an x coordinate.
          # @param x [Numeric] x coordinate
          # @return [Float]
          # @raise [Sevgi::Geometry::Error] when x is not a finite real number
          def y(x) = Nonvertical.y(self, x)

          alias == eql?
        end

        # Vertical linear equation in `x = c` form.
        class Vertical < Linear
          public_class_method :new

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

          # Reports whether a point is on the line.
          # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
          # @return [Boolean]
          # @raise [Sevgi::Geometry::Error] when point cannot be coerced
          def on?(point)
            point = Tuple[Point, point]

            F.eq?(point.x, x(point.y))
          end

          # Returns a parallel vertical equation shifted by offsets.
          #
          # A positive signed distance shifts right in screen coordinates.
          # @param distance [Numeric, nil] signed perpendicular offset
          # @param dx [Numeric, nil] explicit x translation
          # @param dy [Numeric, nil] accepted for signature compatibility and ignored
          # @return [Sevgi::Geometry::Equation::Linear::Vertical]
          # @raise [Sevgi::Geometry::Error] when an operand is not a finite real number
          def shift(distance = nil, dx: nil, dy: nil)
            distance, dx, _dy = shift_values(distance, dx, dy)

            self.class.new(x + distance + dx)
          end

          # Formats the equation for display.
          # @return [String]
          def to_s = "Linear<x = #{F.approx(x)}>"

          # Evaluates x for a y coordinate.
          # @param y [Numeric, nil] ignored finite y coordinate
          # @return [Float]
          # @raise [Sevgi::Geometry::Error] when y is present and not a finite real number
          def x(y = nil)
            Real[:y, y] unless y.nil?
            @x
          end

          # Evaluates y for an x coordinate.
          # @param _x [Numeric] x coordinate
          # @return [void]
          # @raise [Sevgi::Geometry::Error] always, because y is indeterminate
          def y(_x) = Error.("y is indeterminate for a vertical equation")

          alias == eql?
        end
      end
    end
  end
end
