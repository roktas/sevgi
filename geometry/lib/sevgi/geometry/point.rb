# frozen_string_literal: true

module Sevgi
  module Geometry
    # Implementation owner and registry for public affine transformations on Point and lined elements.
    # @api private
    module Affinity
      # Reflects a point across the selected axes.
      #
      # `x:` controls reflection across the x-axis, which negates y. `y:`
      # controls reflection across the y-axis, which negates x.
      # @param x [Boolean] reflect across the x-axis
      # @param y [Boolean] reflect across the y-axis
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when a flag is not Boolean
      def reflect(x: true, y: true)
        Error.("Reflection x flag must be Boolean") unless x.equal?(true) || x.equal?(false)
        Error.("Reflection y flag must be Boolean") unless y.equal?(true) || y.equal?(false)

        with(x: (y ? -1 : 1) * self.x(), y: (x ? -1 : 1) * self.y())
      end

      # Rotates a point around the origin using screen-space degrees.
      # @param a [Numeric] clockwise angle in degrees
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
      def rotate(a)
        a = Real[:angle, a]
        with(x: (x * F.cos(a)) - (y * F.sin(a)), y: (x * F.sin(a)) + (y * F.cos(a)))
      end

      # Scales a point from the origin.
      # @param sx [Numeric] x scale factor
      # @param sy [Numeric, Sevgi::Undefined] y scale factor, defaulting to sx
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when a scale is not a finite real number
      def scale(sx, sy = Undefined)
        sx = Real[:sx, sx]
        sy = Real[:sy, Undefined.default(sy, sx)]
        with(x: sx * x, y: sy * y)
      end

      # Skews a point from the origin.
      # @param ax [Numeric] x-axis skew angle in degrees
      # @param ay [Numeric, Sevgi::Undefined] y-axis skew angle in degrees, defaulting to ax
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when an angle is not a finite real number
      def skew(ax, ay = Undefined)
        ax = Real[:ax, ax]
        ay = Real[:ay, Undefined.default(ay, ax)]
        with(x: x + (y * F.tan(ax)), y: y + (x * F.tan(ay)))
      end

      # Skews a point along x.
      # @param a [Numeric] skew angle in degrees
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
      def skew_x(a) = with(x: x + (y * F.tan(Real[:angle, a])))

      # Skews a point along y.
      # @param a [Numeric] skew angle in degrees
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
      def skew_y(a) = with(y: y + (x * F.tan(Real[:angle, a])))

      # Translates a point.
      # @param dx [Numeric] x offset
      # @param dy [Numeric, Sevgi::Undefined] y offset, defaulting to dx
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when an offset is not a finite real number
      def translate(dx, dy = Undefined)
        dx = Real[:dx, dx]
        dy = Real[:dy, Undefined.default(dy, dx)]
        with(x: x + dx, y: y + dy)
      end
    end

    # Immutable point in SVG/screen coordinates.
    #
    # Use `Point[x, y]` to create a point from two coordinates.
    # @example Measure and rotate a point in screen coordinates
    #   point = Sevgi::Geometry::Point[3, 4]
    #   Sevgi::Geometry::Point.length(Sevgi::Geometry::Origin, point) # => 5.0
    #   point.rotate(90).approx.deconstruct # => [-4.0, 3.0]
    # @!parse
    #   class Point
    #     # Creates a point from two coordinates.
    #     # @param x [Numeric] x coordinate
    #     # @param y [Numeric] y coordinate
    #     # @return [Sevgi::Geometry::Point]
    #     # @raise [Sevgi::Geometry::Error] when a coordinate is not a finite Numeric
    #     # @example Create a point with mathematical notation
    #     #   Sevgi::Geometry::Point[3, 5]
    #     def self.[](x, y); end
    #
    #     # Returns a point reflected across the selected axes.
    #     # @param x [Boolean] reflect across the x-axis
    #     # @param y [Boolean] reflect across the y-axis
    #     # @return [Sevgi::Geometry::Point]
    #     # @raise [Sevgi::Geometry::Error] when a flag is not Boolean
    #     def reflect(x: true, y: true); end
    #
    #     # Returns a point rotated around the origin.
    #     # @param a [Numeric] clockwise angle in degrees
    #     # @return [Sevgi::Geometry::Point]
    #     # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
    #     def rotate(a); end
    #
    #     # Returns a point scaled from the origin.
    #     # @param sx [Numeric] x scale factor
    #     # @param sy [Numeric, Sevgi::Undefined] y scale factor, defaulting to sx
    #     # @return [Sevgi::Geometry::Point]
    #     # @raise [Sevgi::Geometry::Error] when a scale is not a finite real number
    #     def scale(sx, sy = Undefined); end
    #
    #     # Returns a point skewed from the origin.
    #     # @param ax [Numeric] x-axis skew angle in degrees
    #     # @param ay [Numeric, Sevgi::Undefined] y-axis skew angle in degrees, defaulting to ax
    #     # @return [Sevgi::Geometry::Point]
    #     # @raise [Sevgi::Geometry::Error] when an angle is not a finite real number
    #     def skew(ax, ay = Undefined); end
    #
    #     # Returns a point skewed along x.
    #     # @param a [Numeric] skew angle in degrees
    #     # @return [Sevgi::Geometry::Point]
    #     # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
    #     def skew_x(a); end
    #
    #     # Returns a point skewed along y.
    #     # @param a [Numeric] skew angle in degrees
    #     # @return [Sevgi::Geometry::Point]
    #     # @raise [Sevgi::Geometry::Error] when angle is not a finite real number
    #     def skew_y(a); end
    #
    #     # Returns a translated point.
    #     # @param dx [Numeric] x offset
    #     # @param dy [Numeric, Sevgi::Undefined] y offset, defaulting to dx
    #     # @return [Sevgi::Geometry::Point]
    #     # @raise [Sevgi::Geometry::Error] when an offset is not a finite real number
    #     def translate(dx, dy = Undefined); end
    #   end
    Point = Data.define(:x, :y) do
      include Comparable
      include Affinity

      # @!attribute [r] x
      #   @return [Float] x coordinate
      # @!attribute [r] y
      #   @return [Float] y coordinate

      # Returns the screen-space angle from one point to another.
      # @param starting [Sevgi::Geometry::Point, Array<Numeric>] start point
      # @param ending [Sevgi::Geometry::Point, Array<Numeric>] end point
      # @return [Float] clockwise angle in degrees
      # @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      def self.angle(starting, ending)
        starting, ending = Tuples[Point, starting, ending]
        F.atan2(ending.y - starting.y, ending.x - starting.x)
      end

      # Compares two points with optional numeric precision.
      # @param this [Sevgi::Geometry::Point, Array<Numeric>] first point
      # @param that [Sevgi::Geometry::Point, Array<Numeric>] second point
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      def self.eq?(this, that, precision: nil)
        this, that = Tuples[self, this, that]
        F.eq?(this.x, that.x, precision:) && F.eq?(this.y, that.y, precision:)
      end

      # Returns the Euclidean distance between two points.
      # @param starting [Sevgi::Geometry::Point, Array<Numeric>] start point
      # @param ending [Sevgi::Geometry::Point, Array<Numeric>] end point
      # @return [Float]
      # @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      def self.length(starting, ending)
        starting, ending = Tuples[Point, starting, ending]
        ::Math.sqrt(((starting.y - ending.y) ** 2) + ((starting.x - ending.x) ** 2))
      end

      # Returns the origin point.
      # @return [Sevgi::Geometry::Point]
      def self.origin
        new(x: 0.0, y: 0.0)
      end

      # Creates a point.
      # @param x [Numeric] x coordinate
      # @param y [Numeric] y coordinate
      # @return [void]
      # @raise [Sevgi::Geometry::Error] when a coordinate is not a finite Numeric
      def initialize(x:, y:) = super(x: Real[:x, x], y: Real[:y, y])

      # Compares points by x, then y.
      # @param other [Object] point or two-item coordinate array to compare
      # @return [Integer, nil] comparison result, or nil when other is not a valid point value
      def <=>(other)
        deconstruct <=> Tuple[Point, other].deconstruct
      rescue Error
        nil
      end

      # Reports whether this point is at or above another point in screen coordinates.
      # @param other [Sevgi::Geometry::Point, Array<Numeric>] point to compare
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def above?(other) = y <= Tuple[Point, other].y

      # Returns a point rounded to precision.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Sevgi::Geometry::Point]
      def approx(precision = nil) = with(x: F.approx(x, precision), y: F.approx(y, precision))

      # Reports whether this point is at or below another point in screen coordinates.
      # @param other [Sevgi::Geometry::Point, Array<Numeric>] point to compare
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def below?(other) = y >= Tuple[Point, other].y

      # Compares this point with optional numeric precision.
      # @param other [Sevgi::Geometry::Point, Array<Numeric>] point to compare
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def eq?(other, precision: nil) = self.class.eq?(self, other, precision:)

      # Reports strict point equality.
      # @param other [Object] object to compare
      # @return [Boolean]
      def eql?(other) = self.class == other.class && deconstruct == other.deconstruct

      # Returns a hash compatible with strict equality.
      # @return [Integer]
      def hash = [self.class, *deconstruct].hash

      # Reports whether this point is at or left of another point.
      # @param other [Sevgi::Geometry::Point, Array<Numeric>] point to compare
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def left?(other) = x <= Tuple[Point, other].x

      # Reports whether this point is at or right of another point.
      # @param other [Sevgi::Geometry::Point, Array<Numeric>] point to compare
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def right?(other) = x >= Tuple[Point, other].x

      # Formats point coordinates for SVG coordinate-list attributes.
      # @return [String]
      def to_cs = "#{F.approx(x)},#{F.approx(y)}"

      # Formats the point for display.
      # @return [String]
      def to_s = "(#{to_cs})"

      alias_method :==, :eql?
    end

    private_constant :Affinity

    # Origin point in SVG/screen coordinates.
    Origin = Point.origin
  end
end
