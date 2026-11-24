# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class PolygonTest < Minitest::Test
      def test_polygon_closes_points
        polygon = Polygon.([0, 0], [2, 0], [1, 1])

        [
          [Point[0, 0], Point[2, 0], Point[1, 1], Point[0, 0]],
          polygon.points,
          3,
          polygon.segments.size
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_polygon_draw_emits_polygon_points
        attrs = nil
        node = Object.new
        node.define_singleton_method(:polygon) { |**kwargs| attrs = kwargs }

        Polygon.([0, 0], [2, 0], [1, 1]).draw(node, id: "shape")

        assert_equal({points: ["0.0,0.0", "2.0,0.0", "1.0,1.0", "0.0,0.0"], id: "shape"}, attrs)
      end

      def test_polygon_rejects_open_segment_path
        error = assert_raises(Error) { Polygon[Segment.horizontal(1)] }

        assert_equal("Element points must form a closed path", error.message)
      end

      def test_polygon_requires_three_vertices
        assert_raises(Error) { Polygon.([0, 0], [1, 0]) }
      end

      def test_polygon_intersection_handles_many_vertices_and_precision
        sides = 64
        vertices = sides.times.map do |i|
          angle = 360.0 * i / sides
          [10.0 * F.cos(angle), 10.0 * F.sin(angle)]
        end

        polygon = Polygon.(*vertices)

        axis_points = polygon.intersection(Equation.horizontal(0), precision: 6)
        circle_points = polygon.intersection(Ellipse[10, 10].equation, precision: 6)

        assert_equal([Point[-10, 0], Point[10, 0]], axis_points.sort)
        assert_operator(circle_points.size, :>=, 32)
      end
    end
  end
end
