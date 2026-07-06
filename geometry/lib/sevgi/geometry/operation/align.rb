# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      module Align
        extend self

        def align(element, other, alignment = :center)
          offset = alignment(element, other, alignment)

          element.translate(offset.x, offset.y)
        end

        def alignment(element, other, alignment = :center)
          OperationInapplicableError.("Not a Geometric Element: #{other}") unless other.is_a?(Element)

          this, that = element.box, other.box

          case alignment
          when :center
            Point[
              that.position.x + ((that.width - this.width) / 2.0) - this.position.x,
              that.position.y + ((that.height - this.height) / 2.0) - this.position.y
            ]
          when :left
            Point[that.position.x - this.position.x, 0]
          when :right
            Point[(that.position.x + that.width) - (this.position.x + this.width), 0]
          when :top
            Point[0, that.position.y - this.position.y]
          when :bottom
            Point[0, (that.position.y + that.height) - (this.position.y + this.height)]
          else
            ArgumentError.("No such type of alignment: #{alignment}")
          end
        end

        def applicable?(element) = element.respond_to?(:translate)
      end

      register(Align, :align, :alignment)
    end
  end
end
