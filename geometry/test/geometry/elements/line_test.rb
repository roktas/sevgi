# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class LineTest < Minitest::Test
      include Fixtures

      def test_line_345
        [
          53.13, line345.angle,
          5.0,   line345.length
        ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }

        [
          Point[0, 0], line345.position,
          Point[3, 4], line345.ending
        ].each_slice(2) { |expected, actual| assert(Point.eq?(expected, actual)) }
      end

      def test_line_543
        [
          -53.13, line543.angle,
          5.0,    line543.length
        ].each_slice(2) { |expected, actual| assert_in_delta(expected, actual) }

        [
          Point[0, 4], line543.position,
          Point[3, 0], line543.ending
        ].each_slice(2) { |expected, actual| assert(Point.eq?(expected, actual)) }
      end

      def test_line_from_points
        [
          Line.(Origin, [ 1, 3 ]).position, Origin,
          Line.(Origin, [ 1, 3 ]).ending,   Point[1, 3],
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_line_from_segment
        line = Line[5, angle345]

        [
          line345.length,   line.length,
          line345.position, line.position,
          line345.ending,   line.ending
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
