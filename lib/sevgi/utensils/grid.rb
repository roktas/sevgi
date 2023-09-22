# frozen_string_literal: true

module Sevgi
  module Utensils
    class Grid
      Types = Struct.new(:point, :contour, :segment)
      private_constant :Types

      Parts = Struct.new(:halves, :majors, :minors)
      private_constant :Parts

      attr_reader :h, :v

      def initialize(ts)
        @h = Types.new
        @v = Types.new

        compute(ts)
      end

      def all = @all ||= Parts.new(halves: h.point.halves.flatten, majors: h.point.majors.flatten, minors: h.point.minors.flatten)

      alias_method :a, :all

      private

      def compute(ts)
        lps = points(ts.v.ls, ts.h.ls) # array of halve (l) points
        mps = points(ts.v.ms, ts.h.ms) # array of major (m) points
        nps = points(ts.v.ns, ts.h.ns) # array of minor (n) points

        h.point, h.contour, h.segment = parts(lps,           mps,           nps)
        v.point, v.contour, v.segment = parts(lps.transpose, mps.transpose, nps.transpose)
      end

      def parts(lps, mps, nps)
        [
          Parts.new(halves: lps,                   majors: mps,                   minors: nps),                   # points
          Parts.new(halves: [lps.first, lps.last], majors: [mps.first, mps.last], minors: [nps.first, nps.last]), # contours
          Parts.new(halves: segments(lps),         majors: segments(mps),         minors: segments(nps)),         # segments
        ]
      end

      def segments(a)    = a.first.zip(a.last).map { Geometry::Segment[_1, _2] }

      def points(va, ha) = va.map { |y| ha.map { |x| Geometry::Point[x, y] } }
    end
  end
end
