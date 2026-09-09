# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      # Returns the smallest axis-aligned rectangle enclosing all elements.
      #
      # Each element contributes its existing {Sevgi::Geometry::Element#box},
      # including zero-size boxes whose positions may still extend the result.
      # @param elements [Array<Sevgi::Geometry::Element>] elements to enclose
      # @return [Sevgi::Geometry::Rect] aggregate bounding rectangle
      # @raise [Sevgi::ArgumentError] when no elements are given
      # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when an argument is not a geometry element
      # @example Enclose several geometry values
      #   a = Sevgi::Geometry::Rect[10, 5, position: [2, 3]]
      #   b = Sevgi::Geometry::Line.([-4, 8], [20, 12])
      #   Sevgi::Geometry::Operation.box(a, b) # => Rect spanning both elements
      def box(*elements)
        validate_box_elements(elements)
        boxes = elements.map(&:box)

        Rect.from_corners(minimum_corner(boxes), maximum_corner(boxes))
      end

      private

      def maximum_corner(boxes)
        [
          boxes.map { it.position.x + it.width }.max,
          boxes.map { it.position.y + it.height }.max
        ]
      end

      def minimum_corner(boxes)
        [
          boxes.map { it.position.x }.min,
          boxes.map { it.position.y }.min
        ]
      end

      def validate_box_elements(elements)
        ArgumentError.("At least one geometric element required") if elements.empty?

        invalid = elements.find { !it.is_a?(Element) }
        OperationInapplicableError.("Not a Geometric Element: #{invalid}") if invalid
      end
    end
  end
end
