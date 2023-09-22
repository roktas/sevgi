# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    module Equation
      module Line
        class VerticalTest < Minitest::Test
          include Fixtures

          def test_fixtures_construction
            vline3
          end

          def test_vertical
            line = Line.vertical(1.0)

            assert_in_delta(1.0, line.x(1))
            assert_equal(Float::INFINITY, line.y(1))
          end

          def test_vertical_left
            line = Line.vertical(5.0)

            assert(line.left?(Point[-5, 0]))
          end

          def test_vertical_onto
            line = Line.vertical(5.0)

            assert(line.onto?(Point[5, 0]))
            assert(line.onto?(Point[5, -1]))
          end

          def test_vertical_right
            line = Line.vertical(5.0)

            assert(line.right?(Point[10, 0]))
          end

          def test_vertical_vertical_intersection
            line  = Line.vertical(5.0)
            point = line.intersection(Line.vertical(1.0))

            assert_equal(Point[Float::INFINITY, Float::INFINITY], point)
          end

          def test_vertical_diagonal_intersection
            line    = Line.vertical(5.0)
            segment = Segment[Point[-2, -1], Point[0, 1]]
            point   = line.intersection(segment.line).approx

            assert_equal(Point[5, 6], point)
          end
        end
      end
    end
  end
end
