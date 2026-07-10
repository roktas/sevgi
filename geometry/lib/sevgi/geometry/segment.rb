# frozen_string_literal: true

module Sevgi
  module Geometry
    # Immutable polar segment in SVG/screen coordinates.
    #
    # `length` is a distance and `angle` is a clockwise angle in degrees.
    # Use `Segment[length, angle]` to create a segment from polar components.
    Segment = Data.define(:length, :angle) do
      include Comparable

      # @!attribute [r] length
      #   @return [Float] segment length
      # @!attribute [r] angle
      #   @return [Float] clockwise angle in degrees

      # Creates a segment from start and end points.
      # @param starting [Sevgi::Geometry::Point, Array<Numeric>] start point
      # @param ending [Sevgi::Geometry::Point, Array<Numeric>] end point
      # @return [Sevgi::Geometry::Segment]
      # @raise [Sevgi::Geometry::Error] when either point cannot be coerced
      def self.call(starting, ending)
        starting, ending = Tuples[Point, starting, ending]
        self[Point.length(starting, ending), Point.angle(starting, ending)]
      end

      # Compares two segments with optional numeric precision.
      # @param this [Sevgi::Geometry::Segment, Array<Numeric>] first segment
      # @param that [Sevgi::Geometry::Segment, Array<Numeric>] second segment
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when either segment cannot be coerced
      def self.eq?(this, that, precision: nil)
        this, that = Tuples[self, this, that]
        F.eq?(this.length, that.length, precision:) && F.eq?(this.angle, that.angle, precision:)
      end

      # Returns a downward segment.
      # @param length [Numeric] segment length
      # @return [Sevgi::Geometry::Segment]
      def self.downward(length) = self[length, 90.0]

      # Returns a leftward segment.
      # @param length [Numeric] segment length
      # @return [Sevgi::Geometry::Segment]
      def self.leftward(length) = self[length, 180.0]

      # Returns a rightward segment.
      # @param length [Numeric] segment length
      # @return [Sevgi::Geometry::Segment]
      def self.rightward(length) = self[length, 0.0]

      # Returns an upward segment.
      # @param length [Numeric] segment length
      # @return [Sevgi::Geometry::Segment]
      def self.upward(length) = self[length, -90.0]

      class << self
        # @return [Sevgi::Geometry::Segment]
        alias_method :horizontal, :rightward
        # @return [Sevgi::Geometry::Segment]
        alias_method :vertical, :downward
      end

      # Creates a segment.
      # @param length [Numeric] segment length
      # @param angle [Numeric] clockwise angle in degrees
      # @return [void]
      # @raise [Sevgi::Geometry::Error] when a component is not a finite Numeric
      def initialize(length:, angle:) = super(length: Real[:length, length], angle: Real[:angle, angle])

      # Compares segments by length.
      # @param other [Sevgi::Geometry::Segment, Array<Numeric>] segment to compare
      # @return [Integer, nil]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def <=>(other) = length <=> Tuple[Segment, other].length

      # Returns a segment rounded to precision.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Sevgi::Geometry::Segment]
      def approx(precision = nil) = with(length: F.approx(length, precision), angle: F.approx(angle, precision))

      # Returns the endpoint reached from a starting point.
      # @param starting [Sevgi::Geometry::Point, Array<Numeric>] start point
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when starting cannot be coerced
      def ending(starting) = Tuple[Point, starting].translate(x, y)

      # Compares this segment with optional numeric precision.
      # @param other [Sevgi::Geometry::Segment, Array<Numeric>] segment to compare
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when other cannot be coerced
      def eq?(other, precision: nil) = self.class.eq?(self, other, precision:)

      # Reports strict segment equality.
      # @param other [Object] object to compare
      # @return [Boolean]
      def eql?(other) = self.class == other.class && deconstruct == other.deconstruct

      # Returns a hash compatible with strict equality.
      # @return [Integer]
      def hash = [self.class, *deconstruct].hash

      # Converts the segment into a line at a point.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] line start point
      # @return [Sevgi::Geometry::Line]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def line(point = Origin) = Line[length, angle, position: Tuple[Point, point]]

      # Returns the opposite segment.
      # @return [Sevgi::Geometry::Segment]
      def reverse = with(angle: angle + 180.0)

      # Returns the x component of the segment.
      # @return [Float]
      def x = length * F.cos(angle)

      # Returns the y component of the segment.
      # @return [Float]
      def y = length * F.sin(angle)
    end

    # Lightweight polar value used where a plain length/angle tuple is enough.
    Polar = Data.define(:length, :angle)
  end
end
