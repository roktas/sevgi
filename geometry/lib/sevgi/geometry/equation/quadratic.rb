# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      class Quadratic < Equation
      end
    end

    class Circle
      def equation
        raise(NotImplementedError)
      end
    end
  end
end
