# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class TriangleTest < Minitest::Test
      def test_triangle_exposes_side_lengths
        triangle = Triangle[
          [5.0, F.atan2(4.0, 3.0)],
          [4.0, 270.0]
        ]

        [
          5.0,
          triangle.AB.length,
          4.0,
          triangle.BC.length,
          3.0,
          triangle.CA.length
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_triangle_exposes_vertex_shortcuts
        triangle = Triangle[
          [5.0, F.atan2(4.0, 3.0)],
          [4.0, 270.0]
        ]

        [
          triangle.points[0],
          triangle.A(),
          triangle.points[1],
          triangle.B(),
          triangle.points[2],
          triangle.C()
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

        refute_respond_to(triangle, :D)
        refute_respond_to(triangle, :CD)
      end
    end
  end
end
