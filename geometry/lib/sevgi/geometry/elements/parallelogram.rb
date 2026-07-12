# frozen_string_literal: true

module Sevgi
  module Geometry
    # Generated superclass for Parallelogram.
    # @api private
    ParallelogramBase = Element.lined(4)
    private_constant :ParallelogramBase

    # Closed four-sided element built from horizontal and vertical segments.
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

      # Builds a parallelogram from a horizontal segment and tallness constraint.
      # @param horizontal [Sevgi::Geometry::Segment, Array<Numeric>] horizontal segment
      # @param tallness [Sevgi::Geometry::LengthAngle, Array<Numeric>] overall target height and side direction
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or the height constraint is infeasible
      # @example Use an array constraint
      #   Sevgi::Geometry::Parallelogram.new_by_height(horizontal: [4, 0], tallness: [3, 90])
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

        self[horizontal, Segment[height / sine, angle], position:]
      end

      # Builds a parallelogram from a vertical segment and wideness constraint.
      # @param vertical [Sevgi::Geometry::Segment, Array<Numeric>] vertical segment
      # @param wideness [Sevgi::Geometry::LengthAngle, Array<Numeric>] overall target width and side direction
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] starting point
      # @return [Sevgi::Geometry::Parallelogram]
      # @raise [Sevgi::Geometry::Error] when inputs cannot be coerced or the width constraint is infeasible
      # @example Use an array constraint
      #   Sevgi::Geometry::Parallelogram.new_by_width(vertical: [3, 90], wideness: [4, 0])
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

        self[Segment[width / cosine, angle], vertical, position:]
      end
    end
  end
end
