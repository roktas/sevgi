# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class LinedTest < Minitest::Test
      def test_vertices_omit_only_closed_path_repetition
        rect = Rect[3, 4]
        polyline = Polyline.([0, 0], [3, 0], [3, 4])

        assert_equal(rect.points[...-1], rect.vertices)
        assert_same(polyline.points, polyline.vertices)
        assert_equal(4, rect.vertices.size)
        assert_equal(5, rect.points.size)
      end

      def test_vertices_are_immutable
        rect = Rect[3, 4]

        assert_predicate(rect.vertices, :frozen?)
        assert_raises(FrozenError) { rect.vertices << Origin }
      end

      def test_open_lined_traversal_reverses_trace
        line = Line.([0, 0], [3, 4])
        polyline = Polyline.([0, 0], [3, 0], [3, 4])

        [line, polyline].each do |path|
          reverse = path.reverse

          assert_equal(path.ending, reverse.starting)
          assert_equal(path.starting, reverse.ending)
          assert_equal(path.points.reverse, reverse.points)
          assert_equal(path.length, reverse.length)
          assert_equal(path, reverse.reverse)
          assert_instance_of(path.class, reverse)
        end
      end

      def test_generated_open_lined_class_exposes_traversal
        klass = Element.lined(2, open: true)
        path = klass.([0, 0], [2, 0], [2, 1])

        assert_equal(Point[0, 0], path.starting)
        assert_equal(Point[2, 1], path.ending)
        assert_equal(path.points.reverse, path.reverse.points)
      end
    end
  end
end
