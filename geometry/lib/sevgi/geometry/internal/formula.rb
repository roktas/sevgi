# frozen_string_literal: true

module Sevgi
  module Function
    module Formula
      #  Y
      #  ^
      #  |                                     slope (Y/X)
      #  |                                   .
      #  |                                 .
      #  |                             pb +
      #  |                              . . coangle°
      #  |                            .   .
      #  |                          .     .
      #  |                        .       .
      #  |        (hypothenus)   d        dy
      #  |                    .           .
      #  |                  .             .
      #  |            pa  .  angle°   . pc
      #  |              +  .  .  dx .  .  +
      #  |        90° . ..
      #  |          .   .  .
      #  |        .     .    r
      #  |      .       ry    .
      #  |              .       .
      #  |   .          + . rx  . +
      #  | .            .           . noangle°
      #  +--------------+------------+---------------------> X
      #  | intercept (Y)
      #  |
      #  |
      #

      def coangle(angle)                 = 90.0 - angle # complementary angle

      def angler(dx, dy)                 = atan(dy / dx)

      def angles(slope)                  = atan(slope)

      def distance(p, q)                 = ::Math.sqrt(dxp(p, q)**2 + dyp(p, q)**2)

      def height(pa, pb)                 = dyp(pa, pb).abs

      def hypothenus(dx, dy)             = ::Math.sqrt(dx**2 + dy**2)

      def intercept(point, angle, slope) = point.y - (slope * point.x) # point is pa or pb

      def noangle(angle)                 = 90.0 + angle # normal angle

      def rx(r, angle)                   = r * sin(angle)

      def ry(r, angle)                   = r * cos(angle)

      def slopea(angle)                  = tan(angle)

      def sloper(dx, dy)                 = dy / dx

      def width(pa, pb)                  = dxp(pa, pb).abs

      def dxp(pa, pb)                    = pb.x - pa.x

      def dyp(pa, pb)                    = pb.y - pa.y

      def dxa(d, angle)                  = d * cos(angle)

      def dya(d, angle)                  = d * sin(angle)
    end

    extend Formula
  end
end
