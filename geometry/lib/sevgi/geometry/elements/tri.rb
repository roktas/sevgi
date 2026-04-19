# frozen_string_literal: true

module Sevgi
  module Geometry
    class Tri < Element.lined(3)
      def self.[](segment_a, segment_b, position: Origin)
        a, b = Tuples[Segment, segment_a, segment_b]

        length = ::Math.sqrt(a.length ** 2 + b.length ** 2 - 2 * a.length * b.length * F.cos(b.sup - a.angle))
        angle  = b.sup + F.asin(a.length * F.sin(b.sup - a.angle) / length)

        c = Segment[length, angle]

        new_by_segments(a, b, c, position:)
      end
    end
  end
end
