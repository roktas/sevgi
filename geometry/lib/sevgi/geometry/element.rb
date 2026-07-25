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
      #   Instances expose total path `length`; closed classes additionally expose `perimeter`.
      #   @param size [Integer, Sevgi::Undefined] segment count for fixed-size elements, or Undefined for variable size
      #   @param open [Boolean] true for an open path, false for a closed path
      #   @return [Class] subclass of {Sevgi::Geometry::Element::Lined}
      #   @raise [Sevgi::Geometry::Error] when size is not Undefined or a positive Integer, or open is not Boolean
      # @example Define a custom two-segment open shape
      #   Path = Sevgi::Geometry::Element.lined(2, open: true)
      #   Path.([0, 0], [1, 0], [1, 1])
      def self.lined(...) = Lined.send(:build, ...)

      # @overload arced(*args)
      #   Builds an arced element subclass.
      #   @api private
      #   @param args [Array<Object>] arced factory arguments
      #   @return [Class]
      #   @raise [NoMethodError] until arced elements are implemented
      def self.arced(...) = Arced.build(...)

      private_class_method :arced

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

      # Returns equations that define the element boundary.
      # @abstract Subclasses implement element-specific equations.
      # @return [Array<Sevgi::Geometry::Equation>]
      # @raise [Sevgi::PanicError] when a subclass does not implement equations
      def equations = PanicError.("#{self.class}#equations must be implemented")

      # Reports whether the element has zero bounding width and height.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      def ignorable?(precision: nil) = F.zero?(box.width, precision:) && F.zero?(box.height, precision:)

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

      # Element whose boundary is represented by straight segments.
      #
      # The same path is available as immutable {#points}, {#segments}, and
      # {#lines} collections. Closed shapes repeat their first point at the end;
      # open paths do not. Only closed shapes have a filled interior, so
      # `inside?` on an open path is equivalent to testing its boundary.
      # @example Inspect the interchangeable point, segment, and line views
      #   rect = Sevgi::Geometry::Rect[8, 4]
      #   rect.points.size   # => 5
      #   rect.segments.size # => 4
      #   rect.lines.size    # => 4
      # @see Sevgi::Geometry::Operation.sweep
      class Lined < self
        # Open lined element base class.
        # @api private
        Open = Class.new(self) do
          # Draws the element as an SVG polyline.
          # @param node [Object] graphics node receiving the drawing command
          # @return [Object] graphics node command result
          def draw!(node, **) = node.polyline(points: points.map { it.deconstruct.join(",") }, **)

          private :draw!
        end

        # Closed lined element base class.
        # @api private
        Close = Class.new(self) do
          # Creates a closed element from points, appending the first point.
          # @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points
          # @return [Sevgi::Geometry::Element::Lined]
          # @raise [Sevgi::Geometry::Error] when any point cannot be coerced
          def self.new_by_points(*points) = super(*points, points.first)

          # Returns the closed path perimeter.
          # @return [Float]
          def perimeter = length

          # Draws the element as an SVG polygon.
          # @param node [Object] graphics node receiving the drawing command
          # @return [Object] graphics node command result
          def draw!(node, **) = node.polygon(points: points.map { it.deconstruct.join(",") }, **)

          private :draw!

          private_class_method :new_by_points
        end

        # Class methods

        # Point shortcut names generated for fixed-size lined elements.
        # @api private
        SHORTCUTS = ("A".."Z").to_a.freeze
        private_constant :Close, :Open, :SHORTCUTS

        class << self
          private

          # Builds a concrete lined element class.
          # @param size [Integer, Sevgi::Undefined] segment count for fixed-size elements, or Undefined for variable size
          # @param open [Boolean] true for an open path, false for a closed path
          # @return [Class] lined element subclass
          # @raise [Sevgi::Geometry::Error] when size is not Undefined or a positive Integer, or open is not Boolean
          # @api private
          def build(size = Undefined, open: false)
            validate_factory(size, open)

            klass = Class.new(open ? Open : Close)
            klass.define_singleton_method(:close?) { !open }
            klass.define_singleton_method(:poly?) { size.equal?(Undefined) }
            klass.define_singleton_method(:size) { size }
            define_shortcuts(klass, size, open:) unless size.equal?(Undefined)
            klass.public_class_method(:[], :call, :from_points, :from_segments)
            klass.private_class_method(:close?, :poly?, :size)
            klass
          end

          def validate_factory(size, open)
            unless size.equal?(Undefined) || (size.is_a?(::Integer) && size.positive?)
              Error.("Lined segment count must be a positive Integer or Undefined")
            end

            Error.("Lined open flag must be Boolean") unless open.equal?(true) || open.equal?(false)
          end

          # @overload [](*segments, position: Origin)
          #   Builds an element from segments.
          #   @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] boundary segments
          #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
          #   @return [Sevgi::Geometry::Element::Lined]
          #   @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
          # @api private
          def [](...) = new_by_segments(...)

          # @overload call(*points)
          #   Builds an element from points.
          #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points
          #   @return [Sevgi::Geometry::Element::Lined]
          #   @raise [Sevgi::Geometry::Error] when points cannot be coerced
          # @api private
          def call(...) = new_by_points(...)

          # @overload from_points(*points)
          #   Builds an element from points.
          #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points
          #   @return [Sevgi::Geometry::Element::Lined]
          #   @raise [Sevgi::Geometry::Error] when points cannot be coerced
          # @api private
          def from_points(...) = call(...)

          # @overload from_segments(*segments, position: Origin)
          #   Builds an element from segments.
          #   @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] boundary segments
          #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
          #   @return [Sevgi::Geometry::Element::Lined]
          #   @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
          # @api private
          def from_segments(*segments, position: Origin) = self[*segments, position:]

          def affine(*points) = new_by_points!(*points)

          def approximate(*points)
            new_by_points!(*points)
          rescue Error
            (close? ? Polygon : Polyline).send(:new_by_points!, *points)
          end

          # @overload new_by_points(*points)
          #   Builds an element from points, applying closed-path behavior where appropriate.
          #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points
          #   @return [Sevgi::Geometry::Element::Lined]
          #   @raise [Sevgi::Geometry::Error] when points cannot be coerced
          # @api private
          def new_by_points(...) = new_by_points!(...)

          # Builds an element from an exact point path.
          #
          # Closed classes require the closing point to be supplied by the caller.
          # @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] exact boundary points
          # @return [Sevgi::Geometry::Element::Lined]
          # @raise [Sevgi::Geometry::Error] when points cannot be coerced or do not satisfy the class path contract
          # @api private
          def new_by_points!(*points)
            new do
              @points = Tuples[Point, *points]
            end
          end

          # Builds an element from segments and a start position.
          # @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] boundary segments
          # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
          # @return [Sevgi::Geometry::Element::Lined]
          # @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
          # @api private
          def new_by_segments(*segments, position: Origin)
            new do
              @position = Tuple[Point, position]
              @segments = Tuples[Segment, *segments]
            end
          end

          def define_line_shortcuts(klass, point_names, closing:)
            line_names = point_names.each_cons(2).map(&:join)
            line_names << "#{point_names.last}#{point_names.first}" if closing

            line_names.each_with_index do |name, i|
              klass.define_method(name) { lines[i] or Error.("No such line: #{name}") }
            end
          end

          def define_point_shortcuts(klass, point_names)
            point_names.each_with_index do |name, i|
              klass.define_method(name) { points[i] or Error.("No such point: #{name}") }
            end
          end

          def define_shortcuts(klass, size, open:)
            point_names = SHORTCUTS.first([open ? size + 1 : size, SHORTCUTS.size].min)
            define_point_shortcuts(klass, point_names)
            define_line_shortcuts(klass, point_names, closing: !open && point_names.size == size)
          end
        end

        private_class_method :new

        # Creates a lined element from a geometry-definition block.
        # @yield evaluates point or segment definitions in the new element
        # @yieldreturn [Object] ignored block result
        # @return [void]
        # @raise [Sevgi::Geometry::Error] when the block is absent or defines inconsistent geometry
        # @api private
        def initialize(&block)
          super()

          Error.("Constructor block required") unless block

          instance_exec(&block)

          @points ||= calculate_points_from_segments
          @segments ||= calculate_segments_from_points
          freeze_geometry!

          sanitize
          validate_geometry!
        end

        # Core methods

        # Returns an element rebuilt from rounded boundary points.
        #
        # Segments are derived from the rounded points so both representations describe the same path. When rounding
        # breaks a concrete shape invariant, the result widens to a less specific Rect, Polygon, or Polyline rather than
        # retaining a misleading concrete class.
        # @param precision [Integer, nil] decimal precision, or nil for the current function default
        # @return [Sevgi::Geometry::Element::Lined]
        # @raise [Sevgi::ArgumentError] when precision is invalid
        def approx(precision = nil) = self.class.send(:approximate, *rounded_points(precision))

        # @overload draw(node, **attributes)
        #   Draws an approximate element into a graphics node.
        #   @param node [Object] graphics node receiving the drawing command
        #   @param attributes [Hash] drawing attributes
        #   @return [Object] graphics node command result
        def draw(...)
          approx.send(:draw!, ...)
        end

        # Returns immutable element points.
        # @param approximate [Boolean] true to round points with the current function precision
        # @return [Array<Sevgi::Geometry::Point>] frozen point collection
        def points(approximate = false)
          approximate ? rounded_points(nil) : @points
        end

        # Returns the first point.
        # @return [Sevgi::Geometry::Point]
        def position
          @position ||= points.first
        end

        # Returns immutable element segments.
        # @param approximate [Boolean] true to round segments with the current function precision
        # @return [Array<Sevgi::Geometry::Segment>] frozen segment collection
        def segments(approximate = false)
          approximate ? rounded_segments(nil) : @segments
        end

        # Affinity methods

        # Affine operations preserve a shape class while its semantic invariant still holds. Axis-aligned Rect and
        # Square instances widen to Rect or Parallelogram when rotation, skew, or unequal scaling changes that category.

        # @!parse
        #   # Returns an element reflected across the selected axes.
        #   # @param x [Boolean] reflect across the x-axis
        #   # @param y [Boolean] reflect across the y-axis
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   # @raise [Sevgi::Geometry::Error] when a flag is not Boolean
        #   def reflect(x: true, y: true); end
        #
        #   # Returns an element rotated around the origin.
        #   # @param a [Numeric] clockwise angle in degrees
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
        #   def rotate(a); end
        #
        #   # Returns an element scaled from the origin.
        #   # @param sx [Numeric] x scale factor
        #   # @param sy [Numeric, Sevgi::Undefined] y scale factor, defaulting to sx
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   # @raise [Sevgi::Geometry::Error] when a scale is not a finite real number
        #   def scale(sx, sy = Undefined); end
        #
        #   # Returns an element skewed from the origin.
        #   # @param ax [Numeric] x-axis skew angle in degrees
        #   # @param ay [Numeric, Sevgi::Undefined] y-axis skew angle in degrees, defaulting to ax
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   # @raise [Sevgi::Geometry::Error] when an angle is not a finite real number
        #   def skew(ax, ay = Undefined); end
        #
        #   # Returns an element skewed along x.
        #   # @param a [Numeric] skew angle in degrees
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
        #   def skew_x(a); end
        #
        #   # Returns an element skewed along y.
        #   # @param a [Numeric] skew angle in degrees
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
        #   def skew_y(a); end
        #
        #   # Returns an element translated by offset.
        #   # @param dx [Numeric] x offset
        #   # @param dy [Numeric, Sevgi::Undefined] y offset, defaulting to dx
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   # @raise [Sevgi::Geometry::Error] when an offset is not a finite real number
        #   def translate(dx, dy = Undefined); end
        Affinity.public_instance_methods(false).each do |transform|
          define_method(transform) do |*args, **kwargs, &block|
            transformed = points.map { it.public_send(transform, *args, **kwargs, &block) }
            self.class.send(:affine, *transformed)
          end
        end

        # Equality methods

        # Compares element points with optional numeric precision.
        # @param other [Object] object to compare
        # @param precision [Integer, nil] decimal precision, or nil for the current function default
        # @return [Boolean]
        def eq?(other, precision: nil)
          other.instance_of?(self.class) &&
            points.size == other.points.size &&
            points.zip(other.points).all? { |left, right| left.eq?(right, precision:) }
        end

        # Reports strict element equality by class and exact points.
        # @param other [Object] object to compare
        # @return [Boolean]
        def eql?(other) = other.instance_of?(self.class) && points == other.points

        # Returns a hash compatible with strict equality.
        # @return [Integer]
        def hash = [self.class, *points].hash

        alias == eql?

        # Interaction methods

        # Returns immutable boundary equations for all lines.
        # @return [Array<Sevgi::Geometry::Equation::Linear>] frozen equation collection
        def equations = @equations ||= lines.map(&:equation).freeze

        # Intersects the element boundary with an equation.
        #
        # Precision is applied consistently to boundary-membership tolerance, returned-coordinate rounding, and
        # duplicate collapse. A nil precision uses the current thread's function precision for all three stages.
        # @example Intersect a rectangle with a vertical line
        #   rect = Sevgi::Geometry::Rect[8, 4]
        #   axis = Sevgi::Geometry::Equation.vertical(3)
        #   rect.intersection(axis).map(&:deconstruct) # => [[3.0, 0.0], [3.0, 4.0]]
        # @param equation [Sevgi::Geometry::Equation] equation to intersect with
        # @param precision [Integer, nil] decimal precision for returned points, or nil for the current function default
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

        # Properties

        # Returns a line by index.
        # @param i [Integer] line index
        # @return [Sevgi::Geometry::Line]
        # @raise [Sevgi::Geometry::Error] when no line exists for index
        def [](i) = lines[i].tap { |line| Error.("No line exists for index: #{i}") unless line }

        # Returns the bounding rectangle.
        # @return [Sevgi::Geometry::Rect]
        def box = Rect.from_corners([(xs = points.map(&:x)).min, (ys = points.map(&:y)).min], [xs.max, ys.max])

        # Returns a point by index.
        # @param i [Integer] point index
        # @return [Sevgi::Geometry::Point]
        # @raise [Sevgi::Geometry::Error] when no point exists for index
        def call(i) = points[i].tap { Error.("No point exists for index: #{i}") unless it }

        # Returns the first segment.
        # @return [Sevgi::Geometry::Segment]
        def head = @head ||= segments.first

        # Returns immutable boundary lines derived from segments and points.
        # @return [Array<Sevgi::Geometry::Line>] frozen line collection
        def lines
          @lines ||= segments
            .zip(points[...segments.size])
            .map { |segment, position|
              segment.line(position)
            }
            .freeze
        end

        # Returns the total path length.
        # @return [Float]
        def length = @length ||= segments.sum(&:length)

        # Returns the last segment.
        # @return [Sevgi::Geometry::Segment]
        def tail = @tail ||= segments.last

        # Relation methods

        # Reports whether a point is inside or on the boundary.
        #
        # Open paths have no filled interior; for them this predicate is true
        # only for points on the actual path boundary.
        # @example Compare closed and open path containment
        #   rect = Sevgi::Geometry::Rect[8, 4]
        #   line = Sevgi::Geometry::Line.([0, 0], [8, 0])
        #   rect.inside?([4, 2]) # => true
        #   line.inside?([4, 2]) # => false
        #   line.inside?([4, 0]) # => true
        # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
        # @return [Boolean]
        # @raise [Sevgi::Geometry::Error] when point cannot be coerced
        def inside?(point)
          point = Tuple[Point, point]

          return on?(point) unless self.class.send(:close?)

          on?(point) || pnpoly(points, point)
        end

        # Reports whether a point is on the boundary.
        # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
        # @return [Boolean]
        # @raise [Sevgi::Geometry::Error] when point cannot be coerced
        def on?(point)
          point = Tuple[Point, point]

          lines.any? { it.over?(point) }
        end

        # Reports whether a point is outside the element boundary.
        # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
        # @return [Boolean]
        # @raise [Sevgi::Geometry::Error] when point cannot be coerced
        def outside?(point) = !inside?(point)

        private

        def boundary_point?(point, precision)
          return on?(point) if precision.nil?

          F.with_precision(precision) { on?(point) }
        end

        def calculate_points_from_segments
          Error.("No segments found") unless segments

          [point = position, *segments.map { point = it.ending(point) }].tap do |points|
            # Share the first point object when the path closes within the current precision.
            points[-1] = points.first if points.first.eq?(points.last)
          end
        end

        def calculate_segments_from_points
          Error.("No points found") unless points

          points.each_cons(2).map { Segment.(*it) }
        end

        def freeze_geometry!
          @points = @points.dup.freeze
          @segments = @segments.dup.freeze
        end

        # rubocop:disable Metrics/MethodLength
        # https://wrfranklin.org/Research/Short_Notes/pnpoly.html
        def pnpoly(vertices, test)
          result = false

          i = 0
          j = vertices.size - 1

          while i < vertices.size
            if (vertices[i].y > test.y) != (vertices[j].y > test.y) &&
                (test.x < ((vertices[j].x - vertices[i].x) *
                  (test.y - vertices[i].y).to_f /
                  (vertices[j].y - vertices[i].y)) +
                  vertices[i].x)
              result = !result
            end

            j = i
            i += 1
          end

          result
        end
        # rubocop:enable Metrics/MethodLength

        def rounded_points(precision)
          rounded = @points.map { it.approx(precision) }
          rounded[-1] = rounded.first if self.class.send(:close?)
          rounded.freeze
        end

        def rounded_segments(precision)
          rounded_points(precision).each_cons(2).map { Segment.(*it) }.freeze
        end

        def sanitize
          np = self.class.send(:poly?) ? points.size : self.class.send(:size) + 1
          ns = np - 1

          Error.("Wrong number of points;  expected #{np} where found #{points.size}") unless points.size == np
          Error.("Wrong number of segments; expected #{ns} where found #{segments.size}") unless segments.size == ns
          return unless self.class.send(:close?) && !points.first.eq?(points.last)

          Error.("Element points must form a closed path")
        end

        def validate_geometry! = nil
      end

      # Reserved base for future arced elements.
      # @api private
      class Arced < self
      end

      private_constant :Arced
    end

    require_relative "elements/line"
    require_relative "elements/parallelogram"
    require_relative "elements/polygon"
    require_relative "elements/polyline"
    require_relative "elements/rect"
    require_relative "elements/triangle"
  end
end
