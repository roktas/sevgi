# frozen_string_literal: true

module Sevgi
  module Geometry
    # Finite, directed portion of an Ellipse, with less than one full turn.
    # Positive extent is clockwise in screen coordinates. Zero extent has a single-point trace and draws nothing.
    # @example Inspect and reverse an upper semicircle
    #   arc = Sevgi::Geometry::Arc[10, starting_angle: 180, extent: 180]
    #   arc.starting.deconstruct # => [-10.0, 0.0]
    #   arc.reverse.starting == arc.ending
    class Arc < Element::Arced
      # rubocop:disable Metrics/ParameterLists

      # Builds a circular or elliptical arc from dimensions and angles.
      # @param rx [Numeric] positive local x radius
      # @param ry [Numeric] positive local y radius, defaulting to rx
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] parent ellipse center
      # @param rotation [Numeric] clockwise ellipse rotation in degrees
      # @param starting_angle [Numeric] local starting parameter angle in degrees
      # @param extent [Numeric] signed extent strictly between -360 and 360 degrees
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when inputs violate the ellipse or angular invariants
      def self.[](rx, ry = rx, extent:, position: Origin, rotation: 0, starting_angle: 0)
        Ellipse[rx, ry, position:, rotation:].arc(starting_angle:, extent:)
      end

      # rubocop:enable Metrics/ParameterLists

      def self.close? = false
      private_class_method :close?

      # @return [Sevgi::Geometry::Ellipse] immutable parent ellipse
      attr_reader :ellipse
      # @return [Float] signed extent in degrees
      attr_reader :extent
      # @return [Float] local starting parameter angle in degrees
      attr_reader :starting_angle

      # Creates a finite arc. Use the bracket constructor or {Ellipse#arc}.
      # @param ellipse [Sevgi::Geometry::Ellipse] parent ellipse
      # @param starting_angle [Numeric] local starting parameter angle in degrees
      # @param extent [Numeric] signed angular extent in degrees
      # @return [void]
      # @raise [Sevgi::Geometry::Error] when angles are not finite or extent reaches a full turn
      def initialize(ellipse, starting_angle:, extent:)
        super()
        @ellipse = ellipse
        @starting_angle = Real[:starting_angle, starting_angle]
        @extent = Real[:extent, extent]
        Error.("Arc extent must be between -360 and 360 degrees") unless @extent.abs < 360
      end

      # Rebuilds an arc from rounded canonical fields.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when rounding makes a radius zero or extent a full turn
      # @raise [Sevgi::ArgumentError] when precision is invalid
      def approx(precision = nil)
        ellipse
          .approx(precision)
          .arc(starting_angle: F.approx(starting_angle, precision), extent: F.approx(extent, precision))
      end

      # Returns bounds of the finite trace without display rounding.
      # @return [Sevgi::Geometry::Rect]
      def box
        points = [starting, ending, *ellipse.send(:extrema).select { contains_angle?(it) }.map { ellipse.point(it) }]
        xs, ys = points.map(&:x), points.map(&:y)
        Rect.from_corners([xs.min, ys.min], [xs.max, ys.max])
      end

      # Reports whether the parent radii are exactly equal.
      # @return [Boolean]
      def circular? = ellipse.circular?

      # Reports whether the traversal is clockwise.
      # @return [Boolean]
      def clockwise? = extent.positive?

      # Reports whether the traversal is counterclockwise.
      # @return [Boolean]
      def counterclockwise? = extent.negative?

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

      # Draws the finite trace as an SVG path using unrounded geometry.
      # @param node [Object] graphics node receiving the path
      # @param attributes [Hash] SVG attributes
      # @return [Object] graphics command result
      def draw(node, **attributes)
        return node.path(d: "", **attributes) if empty?
        return node.path(d: split_path, **attributes) if extent.abs > 180 && starting == ending

        node.ArcTo(
          x1: starting.x,
          y1: starting.y,
          x2: ending.x,
          y2: ending.y,
          rx:,
          ry:,
          rotation:,
          large: extent.abs > 180,
          sweep: clockwise?,
          **attributes
        )
      end

      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # Reports whether angular extent is exactly zero, independently of numeric precision.
      # @return [Boolean]
      def empty? = extent.zero?

      # Returns the ending point.
      # @return [Sevgi::Geometry::Point]
      def ending = ellipse.point(ending_angle)

      # Returns the unnormalized ending parameter angle.
      # @return [Float]
      def ending_angle = starting_angle + extent

      # Returns the complete parent ellipse carrier.
      # @return [Sevgi::Geometry::Equation::Quadratic]
      def equation = ellipse.equation

      # Returns the immutable parent carrier collection.
      # @return [Array<Sevgi::Geometry::Equation::Quadratic>]
      def equations = ellipse.equations

      # Reports whether a point belongs to the open boundary.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def inside?(point) = on?(point)

      # Returns the non-negative finite-trace length, independently of thread precision.
      # @return [Float]
      # @raise [Sevgi::Geometry::Error] when length is not finite or integration cannot meet its error target
      def length = @length ||= empty? ? 0.0 : ellipse.send(:arc_length, starting_angle, extent)

      # Reports membership using endpoint coordinate tolerance and the finite angular span.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def on?(point)
        point = Tuple[Point, point]
        return true if point.eq?(starting) || point.eq?(ending)

        !empty? && ellipse.on?(point) && contains_angle?(ellipse.send(:parameter, point))
      end

      # Returns the parent ellipse center, not the starting endpoint.
      # @return [Sevgi::Geometry::Point]
      def position = ellipse.position

      # Returns an arc reflected across the selected axes.
      # @param x [Boolean] reflect across the x-axis
      # @param y [Boolean] reflect across the y-axis
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when flags are invalid
      def reflect(x: true, y: true) = affine(:reflect, x:, y:)

      # Reverses traversal without changing the finite trace.
      # @return [Sevgi::Geometry::Arc]
      def reverse = ellipse.arc(starting_angle: ending_angle, extent: -extent)

      # Rotates the arc around the origin without changing local angles.
      # @param angle [Numeric] clockwise angle in degrees
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when angle or resulting geometry is invalid
      def rotate(angle) = ellipse.rotate(angle).arc(starting_angle:, extent:)

      # Returns the parent ellipse rotation in degrees.
      # @return [Float]
      def rotation = ellipse.rotation

      # Returns the parent local x radius.
      # @return [Float]
      def rx = ellipse.rx

      # Returns the parent local y radius.
      # @return [Float]
      def ry = ellipse.ry

      # Scales the arc from the origin, preserving its finite trace and traversal.
      # @param sx [Numeric] x scale factor
      # @param sy [Numeric, Sevgi::Undefined] y factor, defaulting to sx
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when the transform is singular or geometry is invalid
      def scale(sx, sy = Undefined)
        sx, sy = Real[:sx, sx], Real[:sy, Undefined.default(sy, sx)]
        return ellipse.scale(sx, sy).arc(starting_angle:, extent:) if sx == sy

        affine(:scale, sx, sy)
      end

      # Skews the arc from the origin.
      # @param ax [Numeric] x-axis skew angle in degrees
      # @param ay [Numeric, Sevgi::Undefined] y-axis angle, defaulting to ax
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when the transform is singular or geometry is invalid
      def skew(ax, ay = Undefined) = affine(:skew, ax, ay)

      # Skews the arc along x.
      # @param angle [Numeric] skew angle in degrees
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when angle or geometry is invalid
      def skew_x(angle) = affine(:skew_x, angle)

      # Skews the arc along y.
      # @param angle [Numeric] skew angle in degrees
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when angle or geometry is invalid
      def skew_y(angle) = affine(:skew_y, angle)

      # Returns the starting point.
      # @return [Sevgi::Geometry::Point]
      def starting = ellipse.point(starting_angle)

      # Returns a translated arc without changing local angles.
      # @param dx [Numeric] x offset
      # @param dy [Numeric, Sevgi::Undefined] y offset, defaulting to dx
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when offsets or resulting geometry are invalid
      def translate(dx, dy = Undefined) = ellipse.translate(dx, dy).arc(starting_angle:, extent:)

      alias center position

      private

      def affine(...)
        parent, phase, direction = ellipse.send(:affine, ...)
        parent.arc(starting_angle: (direction * starting_angle) + phase, extent: direction * extent)
      end

      def contains_angle?(angle)
        return false if empty?

        difference = clockwise? ? angle - (starting_angle % 360) : (starting_angle % 360) - angle
        difference % 360 <= extent.abs
      end

      # rubocop:disable-next Metrics/AbcSize
      def split_path
        middle = ellipse.point(starting_angle + (extent / 2))
        commands = [middle, ending].map do |point|
          "A #{rx} #{ry} #{rotation} 0 #{clockwise? ? 1 : 0} #{point.x} #{point.y}"
        end

        ["M #{starting.x} #{starting.y}", *commands].join(" ")
      end

      def state = [ellipse, starting_angle, extent]
    end
  end
end
