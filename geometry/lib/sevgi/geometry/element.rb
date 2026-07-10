# frozen_string_literal: true

module Sevgi
  module Geometry
    # Base class for geometric elements.
    class Element
      # @overload lined(size = Undefined, open: false)
      #   Builds a lined element subclass.
      #   @param size [Integer, Sevgi::Undefined] segment count for fixed-size elements, or Undefined for variable size
      #   @param open [Boolean] true for an open path, false for a closed path
      #   @return [Class] subclass of {Sevgi::Geometry::Element::Lined}
      def self.lined(...) = Lined.build(...)

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
      # @param point [Sevgi::Geometry::Point, Array<Numeric>, nil] target position, or nil to keep current position
      # @param dx [Numeric] additional x offset
      # @param dy [Numeric] additional y offset
      # @return [Sevgi::Geometry::Element] translated element
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def at(point = nil, dx: 0, dy: 0)
        point = point ? Tuple[Point, point] : position

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

      # rubocop:disable Metrics/ClassLength
      # Element whose boundary is represented by straight segments.
      class Lined < self
        # Open lined element base class.
        Open = Class.new(self) do
          # Draws the element as an SVG polyline.
          # @param node [Object] graphics node receiving the drawing command
          # @return [Object] graphics node command result
          def draw!(node, **) = node.polyline(points: points.map { it.deconstruct.join(",") }, **)
        end

        # Closed lined element base class.
        Close = Class.new(self) do
          # Creates a closed element from points, appending the first point.
          # @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points
          # @return [Sevgi::Geometry::Element::Lined]
          # @raise [Sevgi::Geometry::Error] when any point cannot be coerced
          def self.new_by_points(*points) = super(*points, points.first)

          # Draws the element as an SVG polygon.
          # @param node [Object] graphics node receiving the drawing command
          # @return [Object] graphics node command result
          def draw!(node, **) = node.polygon(points: points.map { it.deconstruct.join(",") }, **)
        end

        # Class methods

        # Point shortcut names generated for fixed-size lined elements.
        SHORTCUTS = ("A".."Z").to_a.freeze

        # Builds a concrete lined element class.
        # @param size [Integer, Sevgi::Undefined] segment count for fixed-size elements, or Undefined for variable size
        # @param open [Boolean] true for an open path, false for a closed path
        # @return [Class] lined element subclass
        def self.build(size = Undefined, open: false)
          Class.new(open ? Open : Close) do
            define_singleton_method(:close?) { !open }

            define_singleton_method(:open?) { open }

            define_singleton_method(:poly?) { size == Undefined }

            define_singleton_method(:size) { size }

            Lined.send(:define_shortcuts, self, size, open:) unless size == Undefined
          end
        end

        # @overload [](*segments, position: Origin)
        #   Builds an element from segments.
        #   @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] boundary segments
        #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
        #   @return [Sevgi::Geometry::Element::Lined]
        #   @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
        def self.[](...) = from_segments(...)

        # @overload call(*points)
        #   Builds an element from points.
        #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points
        #   @return [Sevgi::Geometry::Element::Lined]
        #   @raise [Sevgi::Geometry::Error] when points cannot be coerced
        def self.call(...) = from_points(...)

        # @overload from_points(*points)
        #   Builds an element from points.
        #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points
        #   @return [Sevgi::Geometry::Element::Lined]
        #   @raise [Sevgi::Geometry::Error] when points cannot be coerced
        def self.from_points(...) = new_by_points(...)

        # @overload from_segments(*segments, position: Origin)
        #   Builds an element from segments.
        #   @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] boundary segments
        #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
        #   @return [Sevgi::Geometry::Element::Lined]
        #   @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
        def self.from_segments(...) = new_by_segments(...)

        # @overload new_by_points(*points)
        #   Builds an element from points, applying closed-path behavior where appropriate.
        #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] boundary points
        #   @return [Sevgi::Geometry::Element::Lined]
        #   @raise [Sevgi::Geometry::Error] when points cannot be coerced
        def self.new_by_points(...) = new_by_points!(...)

        # Builds an element from an exact point path.
        #
        # Closed classes require the closing point to be supplied by the caller.
        # @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] exact boundary points
        # @return [Sevgi::Geometry::Element::Lined]
        # @raise [Sevgi::Geometry::Error] when points cannot be coerced or do not satisfy the class path contract
        def self.new_by_points!(*points)
          new do
            @points = Tuples[Point, *points]
          end
        end

        # Builds an element from segments and a start position.
        # @param segments [Array<Sevgi::Geometry::Segment, Array<Numeric>>] boundary segments
        # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
        # @return [Sevgi::Geometry::Element::Lined]
        # @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
        def self.new_by_segments(*segments, position: Origin)
          new do
            @position = Tuple[Point, position]
            @segments = Tuples[Segment, *segments]
          end
        end

        private_class_method(:new)

        def self.define_line_shortcuts(klass, point_names, open:)
          line_names = point_names.each_cons(2).map(&:join)
          line_names << "#{point_names.last}#{point_names.first}" if !open && point_names.any?

          line_names.each_with_index do |name, i|
            klass.define_method(name) { lines[i] or Error.("No such line: #{name}") }
          end
        end

        def self.define_point_shortcuts(klass, point_names)
          point_names.each_with_index do |name, i|
            klass.define_method(name) { points[i] or Error.("No such point: #{name}") }
          end
        end

        def self.define_shortcuts(klass, size, open:)
          point_names = SHORTCUTS.first([open ? size + 1 : size, SHORTCUTS.size].min)
          define_point_shortcuts(klass, point_names)
          define_line_shortcuts(klass, point_names, open:)
        end

        private_class_method :define_line_shortcuts, :define_point_shortcuts, :define_shortcuts

        def initialize(&block)
          super()

          Error.("Constructor block required") unless block

          instance_exec(&block)

          @points ||= calculate_points_from_segments
          @segments ||= calculate_segments_from_points
          freeze_geometry!

          sanitize
        end

        # Core methods

        # Returns an element with approximate points and segments.
        # @return [Sevgi::Geometry::Element::Lined]
        def approx
          points, segments = points(true), segments(true)
          self.class.send(:new) do
            @points, @segments = points, segments
          end
        end

        # @overload draw(node, **attributes)
        #   Draws an approximate element into a graphics node.
        #   @param node [Object] graphics node receiving the drawing command
        #   @param attributes [Hash] drawing attributes
        #   @return [Object] graphics node command result
        def draw(...)
          approx.draw!(...)
        end

        # Returns immutable element points.
        # @param approximate [Boolean] true to round points with the current function precision
        # @return [Array<Sevgi::Geometry::Point>] frozen point collection
        def points(approximate = false)
          approximate ? @points.map(&:approx).freeze : @points
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
          approximate ? @segments.map(&:approx).freeze : @segments
        end

        # Affinity methods

        # @!parse
        #   # Returns an element reflected across the selected axes.
        #   # @param x [Boolean] reflect across the x-axis
        #   # @param y [Boolean] reflect across the y-axis
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   def reflect(x: true, y: true); end
        #
        #   # Returns an element rotated around the origin.
        #   # @param a [Numeric] clockwise angle in degrees
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   def rotate(a); end
        #
        #   # Returns an element scaled from the origin.
        #   # @param sx [Numeric] x scale factor
        #   # @param sy [Numeric, Sevgi::Undefined] y scale factor, defaulting to sx
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   def scale(sx, sy = Undefined); end
        #
        #   # Returns an element skewed from the origin.
        #   # @param ax [Numeric] x-axis skew angle in degrees
        #   # @param ay [Numeric, Sevgi::Undefined] y-axis skew angle in degrees, defaulting to ax
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   def skew(ax, ay = Undefined); end
        #
        #   # Returns an element skewed along x.
        #   # @param a [Numeric] skew angle in degrees
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   def skew_x(a); end
        #
        #   # Returns an element skewed along y.
        #   # @param a [Numeric] skew angle in degrees
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   def skew_y(a); end
        #
        #   # Returns an element translated by offset.
        #   # @param dx [Numeric] x offset
        #   # @param dy [Numeric, Sevgi::Undefined] y offset, defaulting to dx
        #   # @return [Sevgi::Geometry::Element::Lined]
        #   def translate(dx, dy = Undefined); end
        Geometry::Affinity.instance_methods.each do |transform|
          define_method(transform) do |*args, **kwargs, &block|
            self.class.new_by_points!(*points.map { it.public_send(transform, *args, **kwargs, &block) })
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
        # Boundary membership is tested on unrounded candidate points. `precision:`
        # only rounds returned coordinates and controls duplicate collapse after
        # membership has been accepted. When `precision` is nil, returned points use
        # the current function precision.
        # @param equation [Sevgi::Geometry::Equation] equation to intersect with
        # @param precision [Integer, nil] decimal precision for returned points, or nil for the current function default
        # @return [Array<Sevgi::Geometry::Point>] unique boundary intersection points
        # @raise [Sevgi::Geometry::Error] when equation is not an equation
        # @raise [Sevgi::PanicError] when the equation combination is not implemented
        def intersection(equation, precision: nil)
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
        def [](i) = lines[i].tap { |line| Error.("No line exist for index: #{i}") unless line }

        # Returns the bounding rectangle.
        # @return [Sevgi::Geometry::Rect]
        def box = Rect.from_corners([(xs = points.map(&:x)).min, (ys = points.map(&:y)).min], [xs.max, ys.max])

        # Returns a point by index.
        # @param i [Integer] point index
        # @return [Sevgi::Geometry::Point]
        # @raise [Sevgi::Geometry::Error] when no point exists for index
        def call(i) = points[i].tap { Error.("No point exist for index: #{i}") unless it }

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

        # Returns the sum of segment lengths.
        # @return [Float]
        def perimeter = @perimeter ||= segments.sum(&:length)

        # Returns the last segment.
        # @return [Sevgi::Geometry::Segment]
        def tail = @tail ||= segments.last

        # Relation methods

        # Reports whether a point is inside or on the boundary.
        #
        # Open paths have no filled interior; for them this predicate is true
        # only for points on the actual path boundary.
        # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
        # @return [Boolean]
        # @raise [Sevgi::Geometry::Error] when point cannot be coerced
        def inside?(point)
          point = Tuple[Point, point]

          return on?(point) if self.class.open?

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
            # Perfectionist touch
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

        def sanitize
          np = self.class.poly? ? points.size : self.class.size + 1
          ns = np - 1

          Error.("Wrong number of points;  expected #{np} where found #{points.size}") unless points.size == np
          Error.("Wrong number of segments; expected #{ns} where found #{segments.size}") unless segments.size == ns
          Error.("Element points must form a closed path") if self.class.close? && !points.first.eq?(points.last)
        end
      end

      # Reserved base for future arced elements.
      # @api private
      class Arced < self
      end

      private_constant :Arced
      # rubocop:enable Metrics/ClassLength
    end

    require_relative "elements/line"
    require_relative "elements/parallelogram"
    require_relative "elements/polygon"
    require_relative "elements/polyline"
    require_relative "elements/rect"
    require_relative "elements/triangle"
  end
end
