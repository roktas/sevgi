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
    # @!method self.from_segments(base, side, position: Origin)
    #   Builds a parallelogram from two adjacent segments and derives their opposites.
    #   @param base [Sevgi::Geometry::Segment, Array<Numeric>] segment from A to B
    #   @param side [Sevgi::Geometry::Segment, Array<Numeric>] segment from A to D
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
    # @!method perimeter
    #   Returns the closed path perimeter.
    #   @return [Float]
    # @example Pair mathematical notation with English conveniences
    #   Sevgi::Geometry::Parallelogram[[2, 0], [2, -90]] ==
    #     Sevgi::Geometry::Parallelogram.from_segments([2, 0], [2, -90])
    #   points = [[0, 0], [2, 0], [2, 2], [0, 2]]
    #   Sevgi::Geometry::Parallelogram.(*points) == Sevgi::Geometry::Parallelogram.from_points(*points)
    # @example Compare vertices with the axis-aligned bounding box
    #   shape = Sevgi::Geometry::Parallelogram.([1, 1], [5, 1], [7, 4], [3, 4])
    #   shape.C.deconstruct # => [7.0, 4.0]
    #   shape.box.width     # => 6.0
    #   shape.box.height    # => 3.0
    class Parallelogram < ParallelogramBase
      # Builds a parallelogram from adjacent base and side segments. Both segments originate at `position`; `base`
      # defines AB and `side` defines AD, regardless of their angles.
      # @param base [Sevgi::Geometry::Segment, Array<Numeric>] segment from A to B
      # @param side [Sevgi::Geometry::Segment, Array<Numeric>] segment from A to D
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when segments or position cannot be coerced
      def self.[](base, side, position: Origin)
        base, side = Tuples[Segment, base, side]

        new_by_segments(base, side.reverse, base.reverse, side, position:)
      end

      # Builds a parallelogram from a base and bounding-height constraint. The constraint length is the target height;
      # its signed angle is retained as the direction of the derived side while the component magnitude determines that
      # side's non-negative length.
      # @param base [Sevgi::Geometry::Segment, Array<Numeric>] segment from A to B
      # @param constraint [Sevgi::Geometry::LengthAngle, Array<Numeric>] target height and side direction
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or the height constraint is infeasible
      # @example Use an array constraint
      #   Sevgi::Geometry::Parallelogram.new_by_height(base: [4, 0], constraint: [3, -90])
      # @example Use a LengthAngle constraint
      #   constraint = Sevgi::Geometry::LengthAngle.new(length: 3, angle: 90)
      #   base = Sevgi::Geometry::Segment[4, 0]
      #   Sevgi::Geometry::Parallelogram.new_by_height(base:, constraint:)
      def self.new_by_height(base:, constraint:, position: Origin)
        base = Tuple[Segment, base]
        constraint = Tuple[LengthAngle, constraint]

        height = constraint.length - base.y.abs
        angle = constraint.angle
        sine = F.sin(angle)
        Error.("Parallelogram height is smaller than its base span") if height.negative?
        Error.("Parallelogram height constraint must have a vertical component") if F.zero?(sine)

        self[base, Segment[height / sine.abs, angle], position:]
      end

      # Builds a parallelogram from a side and bounding-width constraint. The constraint length is the target width; its
      # signed angle is retained as the direction of the derived base while the component magnitude determines that
      # base's non-negative length.
      # @param side [Sevgi::Geometry::Segment, Array<Numeric>] segment from A to D
      # @param constraint [Sevgi::Geometry::LengthAngle, Array<Numeric>] target width and base direction
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or the width constraint is infeasible
      # @example Use an array constraint
      #   Sevgi::Geometry::Parallelogram.new_by_width(side: [3, 90], constraint: [4, 180])
      # @example Use a LengthAngle constraint
      #   constraint = Sevgi::Geometry::LengthAngle.new(length: 4, angle: 0)
      #   side = Sevgi::Geometry::Segment[3, 90]
      #   Sevgi::Geometry::Parallelogram.new_by_width(side:, constraint:)
      def self.new_by_width(side:, constraint:, position: Origin)
        side = Tuple[Segment, side]
        constraint = Tuple[LengthAngle, constraint]

        width = constraint.length - side.x.abs
        angle = constraint.angle
        cosine = F.cos(angle)
        Error.("Parallelogram width is smaller than its side span") if width.negative?
        Error.("Parallelogram width constraint must have a horizontal component") if F.zero?(cosine)

        self[Segment[width / cosine.abs, angle], side, position:]
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
