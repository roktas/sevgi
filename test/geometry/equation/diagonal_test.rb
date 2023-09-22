# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    module Equation
      module Line
        class DiagonalTest < Minitest::Test
          include Fixtures

          def test_fixtures_construction
            [
              0.0, segment345.line.y(0),
              4.0, segment543.line.y(0),
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_diagonal_line_construction_basics
            line = Line.diagonal(slope: 2.0, intercept: -10.0)

            [
              -10.0, line.y(0),
              F.atan(2), line.direction,
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_diagonal_line_construction_from_segments
            [
              10.0,  Line.from_segment(Segment.directed(length: 1.0, direction: F.atan(2))).y(5),
              -10.0, Line.from_segment(Segment.directed(length: 1.0, direction: -F.atan(2))).y(5),
            ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }
          end

          def test_different_construction_methods_give_same_results
            line1 = Line.from_segment(
              Segment.directed(position: Point[5.0, 0.0], length: 1.0, direction: F.atan(2)),
            )

            line2 = Line.diagonal(slope: 2.0, intercept: -10.0)

            assert_equal(line1.approx, line2.approx)
          end

          def test_line_shifting_basics
            line = segment345.line.shift(3.0 * F.sin(segment345.direction))

            assert_in_delta(4.0 / 3.0, line.slope)
            assert_in_delta(-4.0, line.intercept)
          end

          def test_line_shifting_with_lines_constructed_from_segments
            direction = F.atan(2)

            line1 = Line.from_segment(
              Segment.directed(length: 1.0, direction:),
            )

            line2 = Line.from_segment(
              Segment.directed(position: Point[5.0, 0.0], length: 1.0, direction:),
            )

            shifted = line1.shift(10.0 * F.sin(90.0 - direction))

            assert_equal(shifted.approx, line2.approx)
          end

          def test_diagonal_diagonal_intersection
            line    = Line.diagonal(slope: 4.0 / 3.0, intercept: -4)
            segment = Segment[Point[-2, -1], Point[0, 1]]
            point   = line.intersection(segment.line).approx

            assert_equal(Point[15, 16], point)
          end

          def test_point_left_position
            assert(Line.from_segment(segment345).left?(Point[-5, 0]))
          end

          def test_point_onto_position
            assert(Line.from_segment(segment345).onto?(Point[0, 0]))
          end

          def test_point_right_position
            assert(Line.from_segment(segment345).right?(Point[5, 0]))
          end
        end
      end
    end
  end
end
