# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      # Base class for quadratic equations.
      class Quadratic < Equation
      end
    end

    # Circle equation support is not implemented yet.
    class Circle
      # Returns the circle equation.
      # @abstract Circle equation support is not implemented yet.
      # @return [Sevgi::Geometry::Equation::Quadratic]
      # @raise [Sevgi::PanicError] until circle equation support is implemented
      def equation
        PanicError.("#{self.class}#equation must be implemented")
      end
    end
  end
end
