# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class PolylineTest < Minitest::Test
      def test_polyline_preserves_open_points
        polyline = Polyline.([0, 0], [2, 0], [1, 1])

        [
          false,
          Polyline.close?,
          true,
          Polyline.open?,
          true,
          Polyline.poly?,
          [Point[0, 0], Point[2, 0], Point[1, 1]],
          polyline.points,
          2,
          polyline.segments.size
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_polyline_builds_from_segments
        polyline = Polyline[Segment.horizontal(2), Segment.vertical(1)]

        [
          [Point[0, 0], Point[2, 0], Point[2, 1]],
          polyline.points,
          [Segment.horizontal(2), Segment.vertical(1)],
          polyline.segments
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_polyline_draw_emits_polyline_points
        attrs = nil
        node = Object.new
        node.define_singleton_method(:polyline) { |**kwargs| attrs = kwargs }

        Polyline.([0, 0], [2, 0], [1, 1]).draw(node, id: "path")

        assert_equal({points: ["0.0,0.0", "2.0,0.0", "1.0,1.0"], id: "path"}, attrs)
      end
    end
  end
end
