# frozen_string_literal: true

require_relative "line/diagonal"
require_relative "line/horizontal"
require_relative "line/vertical"

module Sevgi
  module Geometry
    module Equation
      module Line
        extend self

        def diagonal(slope:, intercept:)
          Diagonal.new(slope:, intercept:)
        end

        def from_direction(point:, direction:)
          return horizontal(point.y) if F.horizontal?(direction)
          return vertical(point.x)   if F.vertical?(direction)

          diagonal(slope: (slope = F.slopea(direction)), intercept: F.intercept(point, direction, slope))
        end

        def from_segment(segment)
          from_direction(point: segment.position, direction: segment.direction)
        end

        def horizontal(const)
          Horizontal.new(const)
        end

        def vertical(const)
          Vertical.new(const)
        end
      end
    end
  end
end
