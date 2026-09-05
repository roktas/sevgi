# frozen_string_literal: true

module Sevgi
  module Geometry
    # rubocop:disable Metrics/ClassLength

    # Immutable ellipse with positive radii, a center, and clockwise axis rotation.
    # Parameter angles belong to the local ellipse axes, not to polar directions from the center.
    # @example Select a finite boundary and inspect its endpoints
    #   ellipse = Sevgi::Geometry::Ellipse[4, 2, position: [10, 20]]
    #   ellipse.point(90).deconstruct # => [10.0, 22.0]
    #   ellipse.arc(starting_angle: 0, extent: 90).ending == ellipse.point(90)
    class Ellipse < Element::Arced
      # Builds an ellipse from local radii and its position.
      # @param rx [Numeric] positive local x radius
      # @param ry [Numeric] positive local y radius
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] ellipse center
      # @param rotation [Numeric] clockwise rotation in degrees
      # @return [Sevgi::Geometry::Ellipse]
      # @raise [Sevgi::Geometry::Error] when inputs are not finite real values or a radius is not positive
      def self.[](rx, ry, position: Origin, rotation: 0) = new(rx, ry, position:, rotation:)

      def self.close? = true
      private_class_method :close?

      # @return [Sevgi::Geometry::Point] ellipse center
      attr_reader :position
      # @return [Float] clockwise rotation of the local axes in degrees
      attr_reader :rotation
      # @return [Float] positive local x radius
      attr_reader :rx
      # @return [Float] positive local y radius
      attr_reader :ry

      # Creates an ellipse. Use the bracket constructor.
      # @param rx [Numeric] positive local x radius
      # @param ry [Numeric] positive local y radius
      # @param position [Sevgi::Geometry::Point, Array<Numeric>] center
      # @param rotation [Numeric] clockwise rotation in degrees
      # @return [void]
      # @raise [Sevgi::Geometry::Error] when an input is invalid
      def initialize(rx, ry, position:, rotation:)
        super()
        @rx, @ry = [[:rx, rx], [:ry, ry]].map do |field, value|
          value = Real[field, value]
          Error.("Ellipse #{field} must be positive") unless value.positive?
          value
        end

        @position = Tuple[Point, position]
        @rotation = Real[:rotation, rotation]
      end

      # Rebuilds an ellipse from rounded canonical fields.
      # @param precision [Integer, nil] decimal precision, or nil for the current function default
      # @return [Sevgi::Geometry::Ellipse, Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when rounding makes a radius zero
      # @raise [Sevgi::ArgumentError] when precision is invalid
      def approx(precision = nil)
        rebuild(
          F.approx(rx, precision),
          F.approx(ry, precision),
          position.approx(precision),
          F.approx(rotation, precision)
        )
      end

      # Selects a finite, directed arc on this ellipse.
      # @param starting_angle [Numeric] local starting parameter angle in degrees
      # @param extent [Numeric] signed angular extent strictly between -360 and 360 degrees
      # @return [Sevgi::Geometry::Arc]
      # @raise [Sevgi::Geometry::Error] when angles are invalid
      def arc(extent:, starting_angle: 0)
        parent = is_a?(Circle) ? Ellipse[rx, ry, position:] : self
        Arc.send(:new, parent, starting_angle:, extent:)
      end

      # rubocop:disable Metrics/AbcSize

      # Returns the axis-aligned bounds without display rounding.
      # @return [Sevgi::Geometry::Rect]
      def box
        cosine, sine = F.cos(rotation), F.sin(rotation)
        dx = ::Math.hypot(rx * cosine, ry * sine)
        dy = ::Math.hypot(rx * sine, ry * cosine)
        Rect.from_corners([position.x - dx, position.y - dy], [position.x + dx, position.y + dy])
      end

      # rubocop:enable Metrics/AbcSize

      # Reports whether the radii are exactly equal.
      # @return [Boolean]
      def circular? = rx == ry

      # rubocop:disable Metrics/AbcSize

      # Draws an SVG ellipse using original geometric values.
      # @param node [Object] graphics node receiving the element
      # @param attributes [Hash] SVG attributes, including an optional outer transform
      # @return [Object] graphics command result
      def draw(node, **attributes)
        unless rotation.zero?
          transform = "rotate(#{rotation} #{position.x} #{position.y})"
          attributes = attributes.merge(transform: [attributes[:transform], transform].compact.join(" "))
        end

        node.ellipse(cx: position.x, cy: position.y, rx:, ry:, **attributes)
      end

      # rubocop:enable Metrics/AbcSize

      # Reports whether the ellipse has zero angular extent. A complete ellipse is never empty.
      # @return [Boolean]
      def empty? = false

      # Returns the complete quadratic carrier.
      # @return [Sevgi::Geometry::Equation::Quadratic]
      def equation = @equation ||= Equation.quadratic(*coefficients, origin: position)

      # Returns the immutable collection containing the complete carrier.
      # @return [Array<Sevgi::Geometry::Equation::Quadratic>]
      def equations = @equations ||= [equation].freeze

      # Reports whether a point is inside or on the boundary.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def inside?(point)
        point = Tuple[Point, point]
        local = local(point)
        ::Math.hypot(local.x / rx, local.y / ry) < 1.0 || on?(point)
      end

      # Returns the perimeter with thread-independent numerical accuracy.
      # @return [Float]
      # @raise [Sevgi::Geometry::Error] when length is not finite or integration cannot meet its error target
      def length = @length ||= arc_length(0, 360)

      # Reports whether a point matches its radial boundary reference at the current coordinate precision.
      # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
      # @return [Boolean]
      # @raise [Sevgi::Geometry::Error] when point cannot be coerced
      def on?(point)
        point = Tuple[Point, point]
        point != position && point.eq?(self.point(parameter(point)))
      end

      # Returns the closed boundary length.
      # @return [Float]
      def perimeter = length

      # Evaluates the boundary at a local parameter angle.
      # @param angle [Numeric] clockwise local angle in degrees
      # @return [Sevgi::Geometry::Point]
      # @raise [Sevgi::Geometry::Error] when angle or the resulting coordinates are not finite
      def point(angle)
        angle = Real[:angle, angle] % 360.0
        Point[rx * F.cos(angle), ry * F.sin(angle)].rotate(rotation).translate(position.x, position.y)
      end

      # Returns a reflected copy, preserving Circle where applicable.
      # @param x [Boolean] reflect across the x-axis
      # @param y [Boolean] reflect across the y-axis
      # @return [Sevgi::Geometry::Ellipse, Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when a flag is not Boolean
      def reflect(x: true, y: true) = affine(:reflect, x:, y:).first

      # Rotates the center around the origin and the ellipse axes by the same angle.
      # @param angle [Numeric] clockwise angle in degrees
      # @return [Sevgi::Geometry::Ellipse, Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when the angle or resulting geometry is invalid
      def rotate(angle)
        angle = Real[:angle, angle]
        rebuild(rx, ry, position.rotate(angle), rotation + angle)
      end

      # rubocop:disable Metrics/AbcSize

      # Scales the ellipse from the origin. Unequal factors can widen Circle to Ellipse.
      # @param sx [Numeric] x scale factor
      # @param sy [Numeric, Sevgi::Undefined] y factor, defaulting to sx
      # @return [Sevgi::Geometry::Ellipse, Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when the transform is singular or the resulting geometry is invalid
      def scale(sx, sy = Undefined)
        sx, sy = Real[:sx, sx], Real[:sy, Undefined.default(sy, sx)]
        return affine(:scale, sx, sy).first unless sx == sy

        rebuild(rx * sx.abs, ry * sy.abs, position.scale(sx, sy), rotation + (sx.negative? ? 180 : 0))
      end

      # rubocop:enable Metrics/AbcSize

      # Skews the ellipse from the origin.
      # @param ax [Numeric] x-axis skew angle in degrees
      # @param ay [Numeric, Sevgi::Undefined] y-axis angle, defaulting to ax
      # @return [Sevgi::Geometry::Ellipse, Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when the transform is singular or the resulting geometry is invalid
      def skew(ax, ay = Undefined) = affine(:skew, ax, ay).first

      # Skews the ellipse along x.
      # @param angle [Numeric] skew angle in degrees
      # @return [Sevgi::Geometry::Ellipse, Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when the angle or resulting geometry is invalid
      def skew_x(angle) = affine(:skew_x, angle).first

      # Skews the ellipse along y.
      # @param angle [Numeric] skew angle in degrees
      # @return [Sevgi::Geometry::Ellipse, Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when the angle or resulting geometry is invalid
      def skew_y(angle) = affine(:skew_y, angle).first

      # Returns a translated copy.
      # @param dx [Numeric] x offset
      # @param dy [Numeric, Sevgi::Undefined] y offset, defaulting to dx
      # @return [Sevgi::Geometry::Ellipse, Sevgi::Geometry::Circle]
      # @raise [Sevgi::Geometry::Error] when offsets or the resulting center are invalid
      def translate(dx, dy = Undefined) = rebuild(rx, ry, position.translate(dx, dy), rotation)

      alias center position

      private

      def affine(...) = Affine.new(self).transform(...)

      def arc_length(starting_angle, extent)
        return Real[:length, rx * F.to_radians(extent.abs)] if circular?

        Length.new(rx, ry).integrate(starting_angle, extent)
      end

      # rubocop:disable-next Metrics/AbcSize
      def coefficients
        cosine, sine = F.cos(rotation), F.sin(rotation)
        a = ((cosine / rx) ** 2) + ((sine / ry) ** 2)
        b = 2 * cosine * sine * (((1.0 / rx) ** 2) - ((1.0 / ry) ** 2))
        c = ((sine / rx) ** 2) + ((cosine / ry) ** 2)
        [a, b, c, 0, 0, -1]
      end

      # rubocop:disable-next Metrics/AbcSize
      def extrema
        cosine, sine = F.cos(rotation), F.sin(rotation)
        x = F.atan2(-ry * sine, rx * cosine)
        y = F.atan2(ry * cosine, rx * sine)
        [x, x + 180, y, y + 180]
      end

      def local(point) = point.translate(-position.x, -position.y).rotate(-rotation)

      def parameter(point)
        point = local(point)
        F.to_degrees(::Math.atan2(point.y / ry, point.x / rx))
      end

      def rebuild(rx, ry, position, rotation)
        return Circle[rx, position:] if is_a?(Circle) && rx == ry

        Ellipse[rx, ry, position:, rotation:]
      end

      def state = [position, rx, ry, rotation]

      require_relative "ellipse/affine"
      require_relative "ellipse/length"
    end

    # rubocop:enable Metrics/ClassLength
  end
end
