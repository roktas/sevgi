# frozen_string_literal: true

module Sevgi
  module Geometry
    # Affine transforms shared by immutable geometry tuples.
    module Affinity
      # Reflects a point across the selected axes.
      #
      # `x:` controls reflection across the x-axis, which negates y. `y:`
      # controls reflection across the y-axis, which negates x.
      # @param x [Boolean] reflect across the x-axis
      # @param y [Boolean] reflect across the y-axis
      # @return [Sevgi::Geometry::Point]
      def reflect(x: true, y: true) = with(x: (y ? -1 : 1) * self.x(), y: (x ? -1 : 1) * self.y())

      # Rotates a point around the origin using screen-space degrees.
      # @param a [Numeric] clockwise angle in degrees
      # @return [Sevgi::Geometry::Point]
      def rotate(a) = with(x: (x * F.cos(a)) - (y * F.sin(a)), y: (x * F.sin(a)) + (y * F.cos(a)))

      # Scales a point from the origin.
      # @param sx [Numeric] x scale factor
      # @param sy [Numeric, Sevgi::Undefined] y scale factor, defaulting to sx
      # @return [Sevgi::Geometry::Point]
      def scale(sx, sy = Undefined) = with(x: sx * x, y: Undefined.default(sy, sx) * y)

      # Skews a point from the origin.
      # @param ax [Numeric] x-axis skew angle in degrees
      # @param ay [Numeric, Sevgi::Undefined] y-axis skew angle in degrees, defaulting to ax
      # @return [Sevgi::Geometry::Point]
      def skew(ax, ay = Undefined) = with(x: x + (y * F.tan(ax)), y: y + (x * F.tan(Undefined.default(ay, ax))))

      # Skews a point along x.
      # @param a [Numeric] skew angle in degrees
      # @return [Sevgi::Geometry::Point]
      def skew_x(a) = with(x: x + (y * F.tan(a)))

      # Skews a point along y.
      # @param a [Numeric] skew angle in degrees
      # @return [Sevgi::Geometry::Point]
      def skew_y(a) = with(y: y + (x * F.tan(a)))

      # Translates a point.
      # @param dx [Numeric] x offset
      # @param dy [Numeric, Sevgi::Undefined] y offset, defaulting to dx
      # @return [Sevgi::Geometry::Point]
      def translate(dx, dy = Undefined) = with(x: x + dx, y: y + Undefined.default(dy, dx))
    end

    # Immutable point in SVG/screen coordinates.
    #
    # Use `Point[x, y]` to create a point from two coordinates.
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
      def initialize(x:, y:) = super(x: x.to_f, y: y.to_f)

      # Compares points by x, then y.
      # @param other [Sevgi::Geometry::Point, Array<Numeric>] point to compare
      # @return [Integer, nil]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def <=>(other) = (other = Tuple[Point, other]).nan? || nan? ? nil : deconstruct <=> other.deconstruct

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

      # Reports whether any coordinate is infinite.
      # @return [Boolean]
      def infinite? = deconstruct.any?(&:infinite?)

      # Reports whether this point is at or left of another point.
      # @param other [Sevgi::Geometry::Point, Array<Numeric>] point to compare
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def left?(other) = x <= Tuple[Point, other].x

      # Reports whether any coordinate is NaN.
      # @return [Boolean]
      def nan? = deconstruct.any?(&:nan?)

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

    # Origin point in SVG/screen coordinates.
    Origin = Point.origin
  end
end
