# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Parallelogram.
    # @api private
    ParallelogramBase = Element.lined(4)
    private_constant :ParallelogramBase

    # Closed four-sided element whose opposite sides are equal and parallel. Every construction path rejects
    # degenerate or unrelated side pairs; affine operations preserve the class while that invariant holds.
    # @!method self.call(*points)
    #   Builds a parallelogram from four boundary points.
    #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] four boundary points
    #   @return [Sevgi::Geometry::Parallelogram]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a parallelogram
    # @!method self.from_segments(horizontal, vertical, position: Origin)
    #   Builds a parallelogram from two adjacent segments and derives their opposites.
    #   @param horizontal [Sevgi::Geometry::Segment, Array<Numeric>] first adjacent segment
    #   @param vertical [Sevgi::Geometry::Segment, Array<Numeric>] second adjacent segment
    #   @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
    #   @return [Sevgi::Geometry::Parallelogram]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a parallelogram
    # @!method self.from_points(*points)
    #   Builds a parallelogram from four boundary points.
    #   @param points [Array<Sevgi::Geometry::Point, Array<Numeric>>] four boundary points
    #   @return [Sevgi::Geometry::Parallelogram]
    #   @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or do not form a parallelogram
    # @!attribute [r] A
    #   @return [Sevgi::Geometry::Point] first vertex
    # @!attribute [r] B
    #   @return [Sevgi::Geometry::Point] second vertex
    # @!attribute [r] C
    #   @return [Sevgi::Geometry::Point] third vertex
    # @!attribute [r] D
    #   @return [Sevgi::Geometry::Point] fourth vertex
    # @!attribute [r] AB
    #   @return [Sevgi::Geometry::Line] side from A to B
    # @!attribute [r] BC
    #   @return [Sevgi::Geometry::Line] side from B to C
    # @!attribute [r] CD
    #   @return [Sevgi::Geometry::Line] side from C to D
    # @!attribute [r] DA
    #   @return [Sevgi::Geometry::Line] side from D to A
    # @example Pair mathematical notation with English conveniences
    #   Parallelogram[[2, 0], [2, -90]] == Parallelogram.from_segments([2, 0], [2, -90])
    #   points = [[0, 0], [2, 0], [2, 2], [0, 2]]
    #   Parallelogram.(*points) == Parallelogram.from_points(*points)
    class Parallelogram < ParallelogramBase
      # Builds a parallelogram from adjacent horizontal and vertical segments.
      # @param horizontal [Sevgi::Geometry::Segment, Array<Numeric>] horizontal segment
      # @param vertical [Sevgi::Geometry::Segment, Array<Numeric>] vertical segment
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
      def self.[](horizontal, vertical, position: Origin)
        horizontal, vertical = Tuples[Segment, horizontal, vertical]

        new_by_segments(horizontal, vertical.reverse, horizontal.reverse, vertical, position:)
      end

      # Builds a parallelogram from a horizontal segment and tallness constraint. The constraint length is the target
      # bounding height; its signed angle is retained as the direction of the derived side while the component magnitude
      # determines that side's non-negative length.
      # @param horizontal [Sevgi::Geometry::Segment, Array<Numeric>] horizontal segment
      # @param tallness [Sevgi::Geometry::LengthAngle, Array<Numeric>] overall target height and side direction
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or the height constraint is infeasible
      # @example Use an array constraint
      #   Sevgi::Geometry::Parallelogram.new_by_height(horizontal: [4, 0], tallness: [3, -90])
      # @example Use a LengthAngle constraint
      #   constraint = Sevgi::Geometry::LengthAngle.new(length: 3, angle: 90)
      #   horizontal = Sevgi::Geometry::Segment[4, 0]
      #   Sevgi::Geometry::Parallelogram.new_by_height(horizontal:, tallness: constraint)
      def self.new_by_height(horizontal:, tallness:, position: Origin)
        horizontal = Tuple[Segment, horizontal]
        tallness = Tuple[LengthAngle, tallness]

        height = tallness.length - horizontal.y.abs
        angle = tallness.angle
        sine = F.sin(angle)
        Error.("Parallelogram height is smaller than its horizontal side span") if height.negative?
        Error.("Parallelogram height angle must have a vertical component") if F.zero?(sine)

        self[horizontal, Segment[height / sine.abs, angle], position:]
      end

      # Builds a parallelogram from a vertical segment and wideness constraint. The constraint length is the target
      # bounding width; its signed angle is retained as the direction of the derived side while the component magnitude
      # determines that side's non-negative length.
      # @param vertical [Sevgi::Geometry::Segment, Array<Numeric>] vertical segment
      # @param wideness [Sevgi::Geometry::LengthAngle, Array<Numeric>] overall target width and side direction
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or the width constraint is infeasible
      # @example Use an array constraint
      #   Sevgi::Geometry::Parallelogram.new_by_width(vertical: [3, 90], wideness: [4, 180])
      # @example Use a LengthAngle constraint
      #   constraint = Sevgi::Geometry::LengthAngle.new(length: 4, angle: 0)
      #   vertical = Sevgi::Geometry::Segment[3, 90]
      #   Sevgi::Geometry::Parallelogram.new_by_width(vertical:, wideness: constraint)
      def self.new_by_width(vertical:, wideness:, position: Origin)
        vertical = Tuple[Segment, vertical]
        wideness = Tuple[LengthAngle, wideness]

        width = wideness.length - vertical.x.abs
        angle = wideness.angle
        cosine = F.cos(angle)
        Error.("Parallelogram width is smaller than its vertical side span") if width.negative?
        Error.("Parallelogram width angle must have a horizontal component") if F.zero?(cosine)

        self[Segment[width / cosine.abs, angle], vertical, position:]
      end

      private

      def validate_geometry!
        a, b, c, d = segments
        valid = opposite?(a, c) && opposite?(b, d) && !F.zero?(cross(a, b))

        Error.("Parallelogram sides must be non-degenerate opposite pairs") unless valid
      end

      def cross(a, b) = (a.x * b.y) - (a.y * b.x)

      def opposite?(a, b) = F.zero?(a.x + b.x) && F.zero?(a.y + b.y)
    end
  end
end
