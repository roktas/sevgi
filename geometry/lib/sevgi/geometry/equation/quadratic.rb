# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      # Base class reserved for future quadratic equation support.
      # @api private
      class Quadratic < Equation
      end

      private_constant :Quadratic
    end

    # Reserved circle element support.
    # @api private
    class Circle
      # Returns the circle equation.
      # @abstract Circle equation support is not implemented yet.
      # @return [Sevgi::Geometry::Equation::Quadratic]
      # @raise [Sevgi::PanicError] until circle equation support is implemented
      def equation
        PanicError.("#{self.class}#equation must be implemented")
      end
    end

    private_constant :Circle
  end
end
