# frozen_string_literal: true

module Sevgi
  module Geometry
    # The Affinity module provides methods for performing affine transformations
    # on geometric objects that include this module (e.g., Point).
    # These transformations include reflection, rotation, scaling, skewing, and translation.
    module Affinity
      # Reflects the object across specified axes.
      #
      # @param x [Boolean] if true, reflects across the y-axis (negates x-coordinate).
      # @param y [Boolean] if true, reflects across the x-axis (negates y-coordinate).
      # @return [Object] a new object with transformed coordinates.
      def reflect(x: true, y: true)     = with(x: (y ? -1 : 1) * self.x, y: (x ? -1 : 1) * self.y)

      # Reflects the object across the x-axis.
      #
      # @return [Object] a new object with its y-coordinate negated.
      def reflect_x                     = with(y: -y)

      # Reflects the object across the y-axis.
      #
      # @return [Object] a new object with its x-coordinate negated.
      def reflect_y                     = with(x: -x)

      # Rotates the object by a given angle (in radians) around the origin.
      #
      # @param a [Float] the angle of rotation in radians.
      # @return [Object] a new object with rotated coordinates.
      def rotate(a)                     = with(x: x * F.cos(a) - y * F.sin(a), y: x * F.sin(a) + y * F.cos(a))

      # Scales the object by given factors.
      # If only `sx` is provided, scales uniformly in both x and y directions.
      #
      # @param sx [Float] the scaling factor for the x-coordinate.
      # @param sy [Float, Undefined] the scaling factor for the y-coordinate. Defaults to `sx`.
      # @return [Object] a new object with scaled coordinates.
      def scale(sx, sy = Undefined)     = with(x: sx * x, y: Undefined.default(sy, sx) * y)

      # Skews the object by given angles (in radians).
      # If only `ax` is provided, skews uniformly in both x and y directions.
      #
      # @param ax [Float] the skew angle for the x-axis.
      # @param ay [Float, Undefined] the skew angle for the y-axis. Defaults to `ax`.
      # @return [Object] a new object with skewed coordinates.
      def skew(ax, ay = Undefined)      = with(x: x + y * F.tan(ax), y: y + x * F.tan(Undefined(ay, ax)))

      # Skews the object along the x-axis by a given angle (in radians).
      #
      # @param a [Float] the skew angle in radians.
      # @return [Object] a new object with x-coordinate skewed.
      def skew_x(a)                     = with(x: x + y * F.tan(a))

      # Skews the object along the y-axis by a given angle (in radians).
      #
      # @param a [Float] the skew angle in radians.
      # @return [Object] a new object with y-coordinate skewed.
      def skew_y(a)                     = with(y: y + x * F.tan(a))

      # Translates the object by given deltas.
      # If only `dx` is provided, translates equally in both x and y directions.
      #
      # @param dx [Float] the translation delta for the x-coordinate.
      # @param dy [Float, Undefined] the translation delta for the y-coordinate. Defaults to `dx`.
      # @return [Object] a new object with translated coordinates.
      def translate(dx, dy = Undefined) = with(x: x + dx, y: y + Undefined.default(dy, dx))
    end

    # The Point class represents a 2D point with x and y coordinates.
    # It uses `Data.define` for immutability and includes `Comparable` and `Affinity` modules.
    Point = Data.define(:x, :y) do
      include Comparable
      include Affinity

      # Calculates the angle (in radians) between two points (or a line segment defined by them)
      # and the positive x-axis.
      #
      # @param starting [Point, Array<Float>] the starting point.
      # @param ending [Point, Array<Float>] the ending point.
      # @return [Float] the angle in radians.
      def self.angle(starting, ending)
        starting, ending = Tuples[Point, starting, ending]
        F.atan2(ending.y - starting.y, ending.x - starting.x)
      end

      # Checks if two points are approximately equal within a given precision.
      #
      # @param this [Point, Array<Float>] the first point.
      # @param that [Point, Array<Float>] the second point.
      # @param precision [Float, nil] the precision for comparison. If nil, uses default precision.
      # @return [Boolean] true if points are approximately equal, false otherwise.
      def self.eq?(this, that, precision: nil)
        this, that = Tuples[self, this, that]
        F.eq?(this.x, that.x, precision:) && F.eq?(this.y, that.y, precision:)
      end

      # Calculates the Euclidean distance between two points.
      #
      # @param starting [Point, Array<Float>] the starting point.
      # @param ending [Point, Array<Float>] the ending point.
      # @return [Float] the distance between the points.
      def self.length(starting, ending)
        starting, ending = Tuples[Point, starting, ending]
        ::Math.sqrt((starting.y - ending.y) ** 2 + (starting.x - ending.x) ** 2)
      end

      # Returns a new Point at the origin (0.0, 0.0).
      #
      # @return [Point] a new point instance representing the origin.
      def self.origin
        new(x: 0.0, y: 0.0)
      end

      # Initializes a new Point object.
      # Coordinates are converted to Floats.
      #
      # @param x [Numeric] the x-coordinate.
      # @param y [Numeric] the y-coordinate.
      # @return [Point] a new point instance.
      def initialize(x:, y:)         = super(x: x.to_f, y: y.to_f)

      # Compares this point with another point.
      # Comparison is based on `deconstruct` (i.e., `[x, y]`).
      # Returns nil if either point contains NaN.
      #
      # @param other [Point, Array<Float>] the other point to compare with.
      # @return [-1, 0, 1, nil] -1 if self is less than other, 0 if equal, 1 if greater, nil if incomparable.
      def <=>(other)                 = ((other = Tuple[Point, other]).nan? || self.nan?) ? nil : deconstruct <=> other.deconstruct

      # Checks if this point is above or at the same y-level as another point.
      #
      # @param other [Point, Array<Float>] the other point.
      # @return [Boolean] true if this point's y-coordinate is less than or equal to the other's.
      def above?(other)              = y <= (other = Tuple[Point, other]).y

      # Returns a new Point with coordinates approximated to a given precision.
      #
      # @param precision [Integer, nil] the number of decimal places for approximation.
      # @return [Point] a new point with approximated coordinates.
      def approx(precision = nil)    = with(x: F.approx(x, precision), y: F.approx(y, precision))

      # Checks if this point is below or at the same y-level as another point.
      #
      # @param other [Point, Array<Float>] the other point.
      # @return [Boolean] true if this point's y-coordinate is greater than or equal to the other's.
      def below?(other)              = y >= (other = Tuple[Point, other]).y

      # Checks if this point is approximately equal to another point within a given precision.
      #
      # @param other [Point, Array<Float>] the other point.
      # @param precision [Float, nil] the precision for comparison.
      # @return [Boolean] true if points are approximately equal.
      def eq?(other, precision: nil) = self.class.eq?(self, other, precision:)

      # Checks if this point is strictly equal to another point (same class and coordinates).
      #
      # @param other [Object] the object to compare with.
      # @return [Boolean] true if objects are of the same class and have identical coordinates.
      def eql?(other)                = self.class == other.class && deconstruct == other.deconstruct

      # Computes the hash code for this point.
      #
      # @return [Integer] the hash code.
      def hash                       = [ self.class, *deconstruct ].hash

      # Checks if either coordinate of the point is infinite.
      #
      # @return [Boolean] true if x or y is infinite.
      def infinite?                  = deconstruct.any?(&:infinite?)

      # Checks if this point is to the left or at the same x-level as another point.
      #
      # @param other [Point, Array<Float>] the other point.
      # @return [Boolean] true if this point's x-coordinate is less than or equal to the other's.
      def left?(other)               = x <= (other = Tuple[Point, other]).x

      # Checks if either coordinate of the point is NaN (Not a Number).
      #
      # @return [Boolean] true if x or y is NaN.
      def nan?                       = deconstruct.any?(&:nan?)

      # Checks if this point is to the right or at the same x-level as another point.
      #
      # @param other [Point, Array<Float>] the other point.
      # @return [Boolean] true if this point's x-coordinate is greater than or equal to the other's.
      def right?(other)              = x >= (other = Tuple[Point, other]).x

      # Returns a comma-separated string representation of the point's coordinates,
      # approximated for display.
      #
      # @return [String] comma-separated approximated coordinates.
      def to_cs                      = "#{F.approx(x)},#{F.approx(y)}"

      # Returns a string representation of the point in the format "(x,y)".
      # Coordinates are approximated.
      #
      # @return [String] string representation of the point.
      def to_s                       = "(#{to_cs})"

      alias_method :==, :eql?
    end

    # Constant representing the origin point (0.0, 0.0).
    Origin = Point.origin
  end
end
