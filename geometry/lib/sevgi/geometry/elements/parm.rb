# frozen_string_literal: true

module Sevgi
  module Geometry
    class Parm < Element.lined(4)
      class << self
        def [](hsegment, vsegment, position: Origin)
          hsegment, vsegment = Tuples[Segment, hsegment, vsegment]

          new_by_segments(
            hsegment,
            vsegment.reverse,
            hsegment.reverse,
            vsegment,
            position:
          )
        end

        def new_by_height(hsegment, length_angle, position: Origin)
          hsegment     = Tuple[Segment, hsegment]
          length_angle = Tuple[LengthAngle, length_angle]

          height = length_angle.length - hsegment.ly
          angle  = length_angle.angle
          length = height / F.sin(angle)

          self[hsegment, Segment[length, angle], position:]
        end

        def new_by_width(vsegment, length_angle, position: Origin)
          vsegment     = Tuple[Segment, vsegment]
          length_angle = Tuple[LengthAngle, length_angle]

          width  = length_angle.length - hsegment.lx
          angle  = length_angle.angle
          length = width / F.cos(angle)

          self[Segment[length, angle], vsegment, position:]
        end
      end
    end
  end
end
