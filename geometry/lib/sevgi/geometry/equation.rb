# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      def self.diagonal(slope:, intercept:) = Linear::Diagonal.new(slope:, intercept:)

      def self.horizontal(const) = Linear::Horizontal.new(const)

      def self.vertical(const) = Linear::Vertical.new(const)

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
          Error.("TODO")
        end

        Array(points)
      end

      def y(_x, ...) = raise NoMethodError, "#{self.class}#y must be implemented"

      private

      def linear_vs_linear(other)
        case [self, other]
        in [Linear::Diagonal, Linear::Diagonal]
          diagonal_vs_diagonal(self, other)
        in [Linear::Diagonal, Linear::Vertical]
          diagonal_vs_vertical(self, other)
        in [Linear::Vertical, Linear::Diagonal]
          diagonal_vs_vertical(other, self)
        in [Linear::Vertical, Linear::Vertical]
          nil
        end
      end

      def diagonal_vs_diagonal(left, right)
        return nil if F.eq?(left.slope, right.slope)

        x = (right.intercept - left.intercept) / (left.slope - right.slope)

        Point[x, left.y(x)]
      end

      def diagonal_vs_vertical(diagonal, vertical)
        x = vertical.x

        Point[x, diagonal.y(x)]
      end

      def linear_vs_quadratic(...)
        raise NotImplementedError
      end

      def quadratic_vs_quadratic(...)
        raise NotImplementedError
      end
    end

    class Point
      def equation(angle)
        return Equation.horizontal(y) if F.zero?(angle % 180.0)
        return Equation.vertical(x) if F.zero?(angle % 90.0)

        Equation.diagonal(slope: (slope = F.tan(angle)), intercept: y - (slope * x))
      end
    end

    class Line
      def equation = position.equation(angle)
    end

    require_relative "equation/linear"
    require_relative "equation/quadratic"
  end
end
