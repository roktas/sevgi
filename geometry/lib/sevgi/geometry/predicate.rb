# frozen_string_literal: true

module Sevgi
  module Geometry
    # Internal helpers shared by public geometry predicates.
    # @api private
    module Predicate
      extend self

      def adjacent_overlap?(a, b, c, precision: nil)
        return false unless orientation(a, b, c, precision:) == 0

        point_on_segment?(c, a, b, precision:) || point_on_segment?(a, b, c, precision:)
      end

      def convex_turns?(vertices, precision: nil)
        turns = vertices.each_index.filter_map do |i|
          turn = orientation(vertices[i], vertices[(i + 1) % vertices.size], vertices[(i + 2) % vertices.size], precision:)
          turn unless turn.zero?
        end

        !turns.empty? && turns.all? { it == turns.first }
      end

      def orientation(a, b, c, precision: nil)
        cross = Cross[b.x - a.x, b.y - a.y, c.x - a.x, c.y - a.y]
        return 0 if F.zero?(cross, precision:)

        F.lt?(cross, 0.0, precision:) ? -1 : 1
      end

      def point_on_segment?(point, a, b, precision: nil)
        orientation(a, b, point, precision:).zero? &&
          F.ge?(point.x, [a.x, b.x].min, precision:) &&
          F.le?(point.x, [a.x, b.x].max, precision:) &&
          F.ge?(point.y, [a.y, b.y].min, precision:) &&
          F.le?(point.y, [a.y, b.y].max, precision:)
      end

      def repeated_vertex?(vertices, precision: nil)
        vertices.each_index.any? do |i|
          ((i + 1)...vertices.size).any? { |j| Point.eq?(vertices[i], vertices[j], precision:) }
        end
      end

      def segments_intersect?(a, b, c, d, precision: nil)
        abc = orientation(a, b, c, precision:)
        abd = orientation(a, b, d, precision:)
        cda = orientation(c, d, a, precision:)
        cdb = orientation(c, d, b, precision:)

        return true if abc != abd && cda != cdb && !abc.zero? && !abd.zero? && !cda.zero? && !cdb.zero?
        return true if abc.zero? && point_on_segment?(c, a, b, precision:)
        return true if abd.zero? && point_on_segment?(d, a, b, precision:)
        return true if cda.zero? && point_on_segment?(a, c, d, precision:)
        return true if cdb.zero? && point_on_segment?(b, c, d, precision:)

        false
      end

      def simple?(vertices, precision: nil)
        return false if repeated_vertex?(vertices, precision:)

        vertices.each_index do |i|
          return false if adjacent_overlap?(
            vertices[i - 1],
            vertices[i],
            vertices[(i + 1) % vertices.size],
            precision:
          )
        end

        edges = vertices.each_index.map { |i| [vertices[i], vertices[(i + 1) % vertices.size]] }
        edges.each_index do |i|
          ((i + 1)...edges.size).each do |j|
            next if j == i + 1
            next if i.zero? && j == edges.size - 1

            return false if segments_intersect?(*edges[i], *edges[j], precision:)
          end
        end

        true
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

        points = Tuples[self, *points]
        origin = points.first
        baseline = points.drop(1).find { !eq?(origin, it, precision:) }
        return true unless baseline

        points.all? do |point|
          F.zero?(
            Cross[
              baseline.x - origin.x,
              baseline.y - origin.y,
              point.x - origin.x,
              point.y - origin.y
            ],
            precision:
          )
        end
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
