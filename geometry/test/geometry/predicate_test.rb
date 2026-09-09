# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class PredicateTest < Minitest::Test
      def test_collinear_accepts_horizontal_vertical_and_diagonal_sets
        assert(Point.collinear?([0, 2], [4, 2], [9, 2]))
        assert(Point.collinear?([3, 0], [3, 4], [3, 9]))
        assert(Point.collinear?([0, 0], [1, 1], [2, 2], [5, 5]))
      end

      def test_collinear_rejects_non_collinear_points
        refute(Point.collinear?([0, 0], [1, 1], [2, 3]))
      end

      def test_collinear_handles_repeated_points
        assert(Point.collinear?([0, 0], [0, 0], [2, 2], [4, 4]))
        assert(Point.collinear?([3, 3], [3, 3], [3, 3]))
      end

      def test_collinear_respects_precision
        points = [[0, 0], [1, 1], [2, 2.0004]]

        assert(Point.collinear?(*points, precision: 3))
        refute(Point.collinear?(*points, precision: 4))
      end

      def test_collinear_requires_three_points
        error = assert_raises(Sevgi::ArgumentError) { Point.collinear?([0, 0], [1, 1]) }

        assert_match(/At least three points/, error.message)
      end

      def test_collinear_rejects_invalid_point
        assert_raises(Error) { Point.collinear?([0, 0], [1, 1], Object.new) }
      end

      def test_polygon_simple_classifies_convex_and_concave_boundaries
        convex = Polygon.([0, 0], [4, 0], [4, 4], [0, 4])
        concave = Polygon.([0, 0], [4, 0], [2, 2], [4, 4], [0, 4])

        assert_predicate(convex, :simple?)
        assert_predicate(concave, :simple?)
      end

      def test_polygon_simple_rejects_self_intersection
        bow_tie = Polygon.([0, 0], [4, 4], [0, 4], [4, 0])

        refute_predicate(bow_tie, :simple?)
      end

      def test_polygon_simple_rejects_repeated_internal_vertex
        polygon = Polygon.([0, 0], [4, 0], [4, 4], [2, 2], [0, 4], [2, 2])

        refute_predicate(polygon, :simple?)
      end

      def test_polygon_simple_rejects_adjacent_edge_overlap
        polygon = Polygon.([0, 0], [4, 0], [2, 0], [4, 4], [0, 4])

        refute_predicate(polygon, :simple?)
      end

      def test_polygon_simple_rejects_nonadjacent_edge_overlap
        polygon = Polygon.([0, 0], [4, 0], [4, 4], [0, 4], [0, 2], [3, 2], [3, 0], [1, 0])

        refute_predicate(polygon, :simple?)
      end

      def test_polygon_convex_accepts_both_orientations
        points = [[0, 0], [4, 0], [4, 4], [0, 4]]

        assert(Polygon.(*points).convex?)
        assert(Polygon.(*points.reverse).convex?)
      end

      def test_polygon_convex_allows_redundant_collinear_edge_vertex
        polygon = Polygon.([0, 0], [2, 0], [4, 0], [4, 4], [0, 4])

        assert_predicate(polygon, :simple?)
        assert_predicate(polygon, :convex?)
        refute_predicate(polygon, :concave?)
      end

      def test_polygon_concave_classification
        polygon = Polygon.([0, 0], [4, 0], [2, 2], [4, 4], [0, 4])

        assert_predicate(polygon, :simple?)
        refute_predicate(polygon, :convex?)
        assert_predicate(polygon, :concave?)
      end

      def test_polygon_self_intersection_is_neither_convex_nor_concave
        polygon = Polygon.([0, 0], [4, 4], [0, 4], [4, 0])

        refute_predicate(polygon, :convex?)
        refute_predicate(polygon, :concave?)
      end

      def test_polygon_fully_collinear_is_neither_convex_nor_concave
        polygon = Polygon.([0, 0], [2, 0], [4, 0])

        refute_predicate(polygon, :simple?)
        refute_predicate(polygon, :convex?)
        refute_predicate(polygon, :concave?)
      end

      def test_polygon_classification_respects_precision
        polygon = Polygon.([0, 0], [4, 0], [4, 4], [2, 3.99996], [0, 4])

        assert(polygon.convex?(precision: 3))
        refute(polygon.concave?(precision: 3))
        refute(polygon.convex?(precision: 4))
        assert(polygon.concave?(precision: 4))
      end
    end
  end
end
