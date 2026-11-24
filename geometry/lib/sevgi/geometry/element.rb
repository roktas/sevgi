# frozen_string_literal: true

module Sevgi
  module Geometry
    # Abstract base class for positioned geometry values.
    #
    # Construct concrete shapes through their class factories. Element
    # operations return new values, and {#box} supplies the axis-aligned bounds
    # used by alignment and tiling helpers.
    class Element
      private_class_method :new

      # @overload lined(size = Undefined, open: false)
      #   Builds a lined element subclass.
      #   Instances expose total path `length`. Closed classes also expose `perimeter`.
      #   @param size [Integer, Sevgi::Undefined] segment count for fixed-size elements, or Undefined for variable size
      #   @param open [Boolean] true for an open path, false for a closed path
      #   @return [Class] subclass of {Sevgi::Geometry::Element::Lined}
      #   @raise [Sevgi::Geometry::Error] when size is not Undefined or a positive Integer, or open is not Boolean
      # @example Define a custom two-segment open shape
      #   Path = Sevgi::Geometry::Element.lined(2, open: true)
      #   Path.([0, 0], [1, 0], [1, 1])
      def self.lined(...) = Lined.send(:build, ...)

      # Core API

      # Returns a copy moved to a point and optional offset.
      # @example Position a copy without mutating the source
      #   source = Sevgi::Geometry::Rect[8, 4, position: [1, 2]]
      #   moved = source.at([10, 20], dx: 2)
      #   source.position.deconstruct # => [1.0, 2.0]
      #   moved.position.deconstruct  # => [12.0, 20.0]
      # @param point [Sevgi::Geometry::Point, Array<Numeric>, nil] target position, or nil to keep current position
      # @param dx [Numeric] additional x offset
      # @param dy [Numeric] additional y offset
      # @return [Sevgi::Geometry::Element] translated element
      # @raise [Sevgi::Geometry::Error] when point or an offset cannot be coerced to finite geometry values
      def at(point = nil, dx: 0, dy: 0)
        point = point ? Tuple[Point, point] : position
        dx = Real[:dx, dx]
        dy = Real[:dy, dy]

        translate(
          (point.x - position.x) + dx,
          (point.y - position.y) + dy
        )
      end

      # Returns the bounding rectangle.
      # @abstract Subclasses implement element-specific bounds.
      # @return [Sevgi::Geometry::Rect]
      # @raise [Sevgi::PanicError] when a subclass does not implement box
      def box = PanicError.("#{self.class}#box must be implemented")

      # Reports whether the element boundary forms a closed path.
      # @return [Boolean]
      def closed? = self.class.send(:close?)

      # Returns carrier equations for candidate boundary intersections.
      # A finite element can represent only part of each carrier.
      # @abstract Subclasses implement element-specific equations.
      # @return [Array<Sevgi::Geometry::Equation>]
      # @raise [Sevgi::PanicError] when a subclass does not implement equations
      def equations = PanicError.("#{self.class}#equations must be implemented")

      # Reports whether the element has zero bounding width and height.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      def ignorable?(precision: nil)
        bounds = box
        F.zero?(bounds.width, precision:) && F.zero?(bounds.height, precision:)
      end

      # Intersects the element boundary with an equation.
      #
      # Precision controls boundary membership, returned-coordinate rounding, and duplicate collapse.
      # A nil precision uses the current thread's function precision for all three stages.
      # @example Intersect a rectangle with a vertical line
      #   rect = Sevgi::Geometry::Rect[8, 4]
      #   axis = Sevgi::Geometry::Equation.vertical(3)
      #   rect.intersection(axis).map(&:deconstruct) # => [[3.0, 0.0], [3.0, 4.0]]
      # @param equation [Sevgi::Geometry::Equation] equation to intersect with
      # @param precision [Integer, nil] coordinate precision, or nil for the current function default
      # @return [Array<Sevgi::Geometry::Point>] unique boundary intersection points
      # @raise [Sevgi::Geometry::Error] when equation is not an equation
      # @raise [Sevgi::PanicError] when the equation combination is not implemented
      def intersection(equation, precision: nil)
        Error.("Must be an equation: #{equation}") unless equation.is_a?(Equation)

        points = equations.flat_map do |candidate|
          equation.intersect(candidate).select { |point| boundary_point?(point, precision) }
        end

        points.map { |point| point.approx(precision) }.uniq
      end

      # Returns the element position.
      # @abstract Subclasses implement element-specific positioning.
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::PanicError] when a subclass does not implement position
      def position = PanicError.("#{self.class}#position must be implemented")

      # Returns a translated copy.
      # @abstract Subclasses implement element-specific translation.
      # @param _x [Numeric] x offset
      # @param _y [Numeric] y offset
      # @return [Sevgi::Geometry::Element]
      # @raise [Sevgi::PanicError] when a subclass does not implement translate
      def translate(_x, _y) = PanicError.("#{self.class}#translate must be implemented")

      def boundary_point?(point, precision)
        return on?(point) if precision.nil?

        F.with_precision(precision) { on?(point) }
      end

      private :boundary_point?
    end

    require_relative "element/lined"
    require_relative "element/arced"

    require_relative "elements/line"
    require_relative "elements/parallelogram"
    require_relative "elements/polygon"
    require_relative "elements/polyline"
    require_relative "elements/rect"
    require_relative "elements/triangle"
    require_relative "elements/ellipse"
    require_relative "elements/circle"
    require_relative "elements/arc"
  end
end
