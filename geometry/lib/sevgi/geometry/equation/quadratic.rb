# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      class Quadratic < Equation
      end
    end

    class Circle
      def equation
        PanicError.("#{self.class}#equation must be implemented")
      end
    end
  end
end
