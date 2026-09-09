# frozen_string_literal: true

module Sevgi
  module Geometry
    # Internal helpers shared by public geometry predicates.
    # @api private
    module Predicate
      extend self

      def adjacent_overlap?(a, b, c, precision: nil)
        orientation(a, b, c, precision:).zero? &&
          (point_on_segment?(c, a, b, precision:) || point_on_segment?(a, b, c, precision:))
      end

      def adjacent_overlap_in?(vertices, precision: nil)
        vertices.each_index.any? do |i|
          adjacent_overlap?(vertices[i - 1], vertices[i], vertices[(i + 1) % vertices.size], precision:)
        end
      end

      def between?(value, a, b, precision: nil)
        minimum, maximum = [a, b].minmax
        F.ge?(value, minimum, precision:) && F.le?(value, maximum, precision:)
      end

      def collinear?(points, precision: nil)
        origin = points.first
        baseline = points.drop(1).find { !Point.eq?(origin, it, precision:) }

        !baseline || points.all? { orientation(origin, baseline, it, precision:).zero? }
      end

      def convex_turns?(vertices, precision: nil)
        turns = turn_orientations(vertices, precision:)
        !turns.empty? && turns.uniq.one?
      end

      def edges(vertices)
        vertices.each_index.map { |i| [vertices[i], vertices[(i + 1) % vertices.size]] }
      end

      def nonadjacent_intersection?(vertices, precision: nil)
        nonadjacent_pairs(edges(vertices)).any? do |a, b|
          segments_intersect?(*a, *b, precision:)
        end
      end

      def nonadjacent_pairs(edges)
        edges.each_index.flat_map do |i|
          ((i + 1)...edges.size).filter_map do |j|
            [edges[i], edges[j]] unless adjacent_indices?(i, j, edges.size)
          end
        end
      end

      def orientation(a, b, c, precision: nil)
        cross = Cross[b.x - a.x, b.y - a.y, c.x - a.x, c.y - a.y]
        return 0 if F.zero?(cross, precision:)

        F.lt?(cross, 0.0, precision:) ? -1 : 1
      end

      def point_on_segment?(point, a, b, precision: nil)
        orientation(a, b, point, precision:).zero? &&
          between?(point.x, a.x, b.x, precision:) &&
          between?(point.y, a.y, b.y, precision:)
      end

      def repeated_vertex?(vertices, precision: nil)
        vertices.each_index.any? do |i|
          ((i + 1)...vertices.size).any? { |j| Point.eq?(vertices[i], vertices[j], precision:) }
        end
      end

      def segments_intersect?(a, b, c, d, precision: nil)
        first = [a, b]
        second = [c, d]
        turns = segment_orientations(*first, *second, precision:)

        proper_intersection?(turns) || boundary_intersection?(first, second, turns, precision:)
      end

      def simple?(vertices, precision: nil)
        !repeated_vertex?(vertices, precision:) &&
          !adjacent_overlap_in?(vertices, precision:) &&
          !nonadjacent_intersection?(vertices, precision:)
      end

      private

      def adjacent_indices?(i, j, size) = j == i + 1 || (i.zero? && j == size - 1)

      def boundary_intersection?(first, second, turns, precision: nil)
        a, b = first
        c, d = second
        candidates = [[turns[0], c, a, b], [turns[1], d, a, b], [turns[2], a, c, d], [turns[3], b, c, d]]

        candidates.any? { |turn, point, from, to| turn.zero? && point_on_segment?(point, from, to, precision:) }
      end

      def proper_intersection?(turns)
        turns.none?(&:zero?) && turns[0] != turns[1] && turns[2] != turns[3]
      end

      def segment_orientations(a, b, c, d, precision: nil)
        [
          orientation(a, b, c, precision:),
          orientation(a, b, d, precision:),
          orientation(c, d, a, precision:),
          orientation(c, d, b, precision:)
        ]
      end

      def turn_orientations(vertices, precision: nil)
        vertices.each_index
          .map { |i| orientation(vertices[i], vertices[(i + 1) % vertices.size], vertices[(i + 2) % vertices.size], precision:) }
          .reject(&:zero?)
      end
    end

    private_constant :Predicate

    class Point
      # Reports whether three or more points lie on one infinite line.
      #
      # Repeated points are allowed. When every point is equal at the selected
      # precision, the set is collinear.
      # @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] point-like values
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      # @raise [Sevgi::ArgumentError] when fewer than three points are given
      # @raise [Sevgi::Geometry::Error] when a point cannot be coerced
      # @example Test a point set
      #   Sevgi::Geometry::Point.collinear?([0, 0], [1, 1], [2, 2]) # => true
      def self.collinear?(*points, precision: nil)
        ArgumentError.("At least three points required") if points.size < 3

        Predicate.collinear?(Tuples[self, *points], precision:)
      end
    end

    class Polygon
      # Reports whether the polygon boundary has no self-intersection.
      #
      # Adjacent edges may meet only at their shared endpoint. Non-adjacent
      # touches and overlaps make the polygon non-simple.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      def simple?(precision: nil) = Predicate.simple?(vertices, precision:)

      # Reports whether this is a simple polygon whose non-collinear turns all have one orientation.
      #
      # Redundant vertices on straight edges are permitted. Self-intersecting
      # and fully degenerate polygons are not convex.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      def convex?(precision: nil)
        simple?(precision:) && Predicate.convex_turns?(vertices, precision:)
      end

      # Reports whether this is a simple non-convex polygon.
      #
      # Self-intersecting and degenerate polygons are neither convex nor concave.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      def concave?(precision: nil)
        simple?(precision:) && !Predicate.convex_turns?(vertices, precision:)
      end
    end
  end
end
