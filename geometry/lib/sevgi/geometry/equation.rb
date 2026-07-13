# frozen_string_literal: true

module Sevgi
  module Geometry
    # Abstract base class for geometric equations. Construct linear equations through the class factories below.
    class Equation
      private_class_method :new

      # Builds a non-axis-aligned linear equation.
      # @param slope [Numeric] line slope
      # @param intercept [Numeric] y-intercept
      # @return [Sevgi::Geometry::Equation::Linear::Diagonal]
      # @raise [Sevgi::Geometry::Error] when a coefficient is not finite Numeric or slope is zero
      def self.diagonal(slope:, intercept:) = Linear::Diagonal.new(slope:, intercept:)

      # Builds a horizontal linear equation.
      # @param const [Numeric] y coordinate
      # @return [Sevgi::Geometry::Equation::Linear::Horizontal]
      # @raise [Sevgi::Geometry::Error] when const is not a finite Numeric
      def self.horizontal(const) = Linear::Horizontal.new(const)

      # Builds a vertical linear equation.
      # @param const [Numeric] x coordinate
      # @return [Sevgi::Geometry::Equation::Linear::Vertical]
      # @raise [Sevgi::Geometry::Error] when const is not a finite Numeric
      def self.vertical(const) = Linear::Vertical.new(const)

      # Intersects this equation with another equation.
      # @param other [Sevgi::Geometry::Equation] equation to intersect with
      # @return [Array<Sevgi::Geometry::Point>] intersection points
      # @raise [Sevgi::Geometry::Error] when other is not an equation
      # @raise [Sevgi::PanicError] when the equation combination is not implemented
      def intersect(other)
        Error.("Must be an equation: #{other}") unless other.is_a?(Equation)

        points = case [self, other]
        in [Linear, Linear]
          linear_vs_linear(other)
        in [Linear, Quadratic]
          linear_vs_quadratic(other)
        in [Quadratic, Quadratic]
          quadratic_vs_quadratic(other)
        else
          PanicError.("Intersection not implemented: #{self.class} / #{other.class}")
        end

        Array(points)
      end

      # Evaluates y for an x coordinate.
      # @abstract Subclasses implement equation-specific mapping.
      # @param _x [Numeric] x coordinate
      # @return [Float]
      # @raise [Sevgi::PanicError] when a subclass does not implement y
      def y(_x, ...) = PanicError.("#{self.class}#y must be implemented")

      private

      def linear_vs_linear(other)
        case [linear_category(self), linear_category(other)]
        in [:vertical, :vertical]
          nil
        in [:vertical, :nonvertical]
          nonvertical_vs_vertical(other, self)
        in [:nonvertical, :vertical]
          nonvertical_vs_vertical(self, other)
        in [:nonvertical, :nonvertical]
          nonvertical_vs_nonvertical(self, other)
        end
      end

      def linear_category(equation)
        return :vertical if equation.is_a?(Linear::Vertical)
        return :nonvertical if equation.is_a?(Linear::Diagonal) || equation.is_a?(Linear::Horizontal)

        PanicError.("Linear equation category not implemented: #{equation.class}")
      end

      def nonvertical_vs_nonvertical(left, right)
        return nil if F.eq?(left.slope, right.slope)

        x = (right.intercept - left.intercept) / (left.slope - right.slope)

        Point[x, left.y(x)]
      end

      def nonvertical_vs_vertical(nonvertical, vertical)
        x = vertical.x

        Point[x, nonvertical.y(x)]
      end

      def linear_vs_quadratic(...)
        PanicError.("Linear/quadratic intersection must be implemented")
      end

      def quadratic_vs_quadratic(...)
        PanicError.("Quadratic/quadratic intersection must be implemented")
      end
    end

    class Point
      # Returns the linear equation passing through this point at an angle.
      # @param angle [Numeric] clockwise angle in degrees
      # @return [Sevgi::Geometry::Equation::Linear]
      def equation(angle)
        return Equation.horizontal(y) if F.zero?(angle % 180.0)
        return Equation.vertical(x) if F.zero?(angle % 90.0)

        Equation.diagonal(slope: (slope = F.tan(angle)), intercept: y - (slope * x))
      end
    end

    class Line
      # Returns the linear equation containing this line.
      # @return [Sevgi::Geometry::Equation::Linear]
      def equation = position.equation(angle)
    end

    require_relative "equation/linear"
    require_relative "equation/quadratic"
  end
end
