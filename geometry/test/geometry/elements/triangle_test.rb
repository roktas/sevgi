# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class TriangleTest < Minitest::Test
      def test_triangle_closes_segment_pairs
        [
          [Segment[3, 0], Segment[4, 60]],
          [Segment[2, 0], Segment[1, 150]],
          [Segment[1, 150], Segment[2, 0]],
          [Segment[5, 30], Segment[2, -80]]
        ].each do |a, b|
          triangle = Triangle[a, b]
          endpoint = triangle.segments.reduce(Origin) { |point, segment| segment.ending(point) }
          closing_start = b.ending(a.ending(Origin))

          assert(endpoint.eq?(Origin), "expected #{a.inspect}, #{b.inspect} to close")
          assert(triangle.segments.last.ending(closing_start).eq?(Origin), "expected direct closing segment")
        end
      end

      def test_triangle_rejects_degenerate_segments
        [
          [Segment[0, 0], Segment[1, 90]],
          [Segment[1, 0], Segment[0, 90]],
          [Segment[1, 0], Segment[1, 0]],
          [Segment[1, 0], Segment[1, 180]]
        ].each do |a, b|
          error = assert_raises(Error) { Triangle[a, b] }

          assert_equal("Triangle segments must form a non-degenerate triangle", error.message)
        end
      end

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
        ].each_slice(2) { |expected, actual| assert(F.eq?(expected, actual)) }
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
