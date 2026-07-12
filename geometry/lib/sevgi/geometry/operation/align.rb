# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      # Alignment operation implementation.
      # @api private
      module Align
        extend self

        # Returns an element translated to align with another element.
        # @param element [Sevgi::Geometry::Element] element to move
        # @param other [Sevgi::Geometry::Element] reference element
        # @param alignment [Symbol] one of :center, :left, :right, :top, or :bottom
        # @return [Sevgi::Geometry::Element] translated element
        # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when other is not a geometry element
        # @raise [Sevgi::ArgumentError] when alignment is unknown
        def align(element, other, alignment = :center)
          offset = alignment(element, other, alignment)

          element.translate(offset.x, offset.y)
        end

        # Returns the offset needed to align one element with another.
        # @param element [Sevgi::Geometry::Element] element to move
        # @param other [Sevgi::Geometry::Element] reference element
        # @param alignment [Symbol] one of :center, :left, :right, :top, or :bottom
        # @return [Sevgi::Geometry::Point] translation offset
        # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when other is not a geometry element
        # @raise [Sevgi::ArgumentError] when alignment is unknown
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

        # Reports whether the alignment handler can operate on an element.
        # @api private
        # @param element [Object] candidate element
        # @return [Boolean]
        def applicable?(element) = element.respond_to?(:translate)
      end

      register(Align, :align, :alignment)

      private_constant :Align
    end
  end
end
