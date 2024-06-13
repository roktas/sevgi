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
      end
    end
  end
end
