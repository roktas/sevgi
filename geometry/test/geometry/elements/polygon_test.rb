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
    end
  end
end
