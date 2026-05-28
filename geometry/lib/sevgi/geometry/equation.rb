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
          y = self.y(x = (other.intercept - intercept) / (slope - other.slope))
        in [Linear::Diagonal, Linear::Vertical]
          y = self.y(x = other.x)
        in [Linear::Vertical, Linear::Diagonal]
          y = other.y(x = self.x())
        in [Linear::Vertical, Linear::Vertical]
          x, y = ::Float::INFINITY, ::Float::INFINITY
        end

        Point[x, y]
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
