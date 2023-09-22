# frozen_string_literal: true

module Sevgi
  module Geometry
    module Equation
      module Line
        class Horizontal < Diagonal
          def initialize(c)
            super(slope: 0, intercept: c)
          end
        end
      end
    end
  end
end
