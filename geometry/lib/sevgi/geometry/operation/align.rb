# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      module Align
        def align(element, other, alignment = :center)
          alignment(element, other, alignment).apply(element)
        end

        # codebeat:disable[ABC,LOC]
        def alignment(element, other, alignment = :center)
          this, that = element.box, other.box

          case alignment
          when :center then Translation[(this.width - that.width) / 2.0, (this.height - that.height) / 2.0]
          when :left   then Translation[this.ne.x - that.ne.x, 0]
          when :right  then Translation[this.sw.x - that.sw.x, 0]
          when :top    then Translation[0, this.ne.y - that.ne.y]
          when :bottom then Translation[0, this.sw.y - that.sw.y]
          else              ArgumentError.("No such type of alignment: #{alignment}")
          end
        end
        # codebeat:enable[ABC,LOC]

        def applicable?(element)
          Translation.applicable?(element)
        end
      end

      register(Align, :align, :alignment)
    end
  end
end
