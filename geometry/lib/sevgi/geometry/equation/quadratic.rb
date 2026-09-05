# frozen_string_literal: true

module Sevgi
  module Geometry
    class Equation
      # Implicit second-degree carrier with an optional local coordinate origin.
      # The origin avoids expanding large ellipse centers into coefficients that lose the radius through cancellation.
      # @example Intersect a unit circle carrier with a horizontal line
      #   equation = Sevgi::Geometry::Equation.quadratic(1, 0, 1, 0, 0, -1)
      #   equation.y(0) # => [-1.0, 1.0]
      class Quadratic < Equation
        public_class_method :new

        # @return [Array<Float>] immutable coefficients in a, b, c, d, e, f order
        attr_reader :coefficients
        # @return [Sevgi::Geometry::Point] local coordinate origin
        attr_reader :origin

        # Creates a quadratic equation in local coordinates.
        # @param coefficients [Array<Numeric>] six finite coefficients, with a nonzero second-degree term
        # @param origin [Sevgi::Geometry::Point, Array<Numeric>] local coordinate origin
        # @return [void]
        # @raise [Sevgi::Geometry::Error] when coefficients or origin are invalid
        def initialize(*coefficients, origin: Origin)
          super()
          Error.("Quadratic equation requires six coefficients") unless coefficients.size == 6
          @coefficients = coefficients.each_with_index.map { |value, i| Real[("a".."f").to_a[i], value] }.freeze
          Error.("Quadratic equation requires a second-degree term") if @coefficients.first(3).all?(&:zero?)
          @origin = Tuple[Point, origin]
        end

        # Reports exact equality of coefficients and the local origin.
        # @param other [Object] comparison target
        # @return [Boolean]
        def eql?(other) = other.instance_of?(self.class) && coefficients == other.coefficients && origin == other.origin

        # Returns a hash compatible with strict equality.
        # @return [Integer]
        def hash = [self.class, coefficients, origin].hash

        # rubocop:disable Metrics/AbcSize

        # Returns the finite y roots at a world x coordinate, in ascending order.
        # @param x [Numeric] finite world x coordinate
        # @return [Array<Float>] zero, one, or two y coordinates
        # @raise [Sevgi::Geometry::Error] when x or a result is not finite, or y is indeterminate
        def y(x)
          x = Real[:x, x] - origin.x
          a, b, c, d, e, f = coefficients
          roots = roots(c, sum(b * x, e), sum(a * x * x, d * x, f))
          Error.("y is indeterminate for this quadratic equation") unless roots
          roots.map { Real[:y, it + origin.y] }
        end

        # rubocop:enable Metrics/AbcSize

        # @return [Boolean] exact equality of coefficients and origin
        alias == eql?

        private

        # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
        def intersect_linear(line)
          if line.is_a?(Linear::Vertical)
            x = line.x - origin.x
            a, b, c, d, e, f = coefficients
            ys = roots(c, sum(b * x, e), sum(a * x * x, d * x, f))
            return Array(ys).map { Point[line.x, it + origin.y] }
          end

          a, b, c, d, e, f = coefficients
          slope, intercept = line.slope, line.y(origin.x) - origin.y
          xs = roots(
            sum(a, b * slope, c * slope * slope),
            sum(b * intercept, 2 * c * slope * intercept, d, e * slope),
            sum(c * intercept * intercept, e * intercept, f)
          )
          Array(xs).map { |x| Point[x + origin.x, (slope * x) + intercept + origin.y] }
        end

        # rubocop:disable-next Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        def roots(a, b, c)
          scale = [a.abs, b.abs, c.abs].max
          return nil if scale.zero?
          Error.("Quadratic intersection coefficients are not finite") unless scale.finite?
          a, b, c = [a, b, c].map { it / scale }
          return b.zero? ? [] : [-c / b] if a.zero?

          square, product = b * b, 4 * a * c
          discriminant = square - product
          # Only arithmetic cancellation at a tangent can merge roots; display precision does not classify them.
          discriminant = 0.0 if discriminant.abs <= 8 * Float::EPSILON * (square.abs + product.abs)
          return [] if discriminant.negative?
          return [-b / (2 * a)] if discriminant.zero?

          root = ::Math.sqrt(discriminant)
          q = -0.5 * (b + (b.negative? ? -root : root))
          [q / a, c / q].sort
        end

        # Substitution can cancel before the discriminant is formed, notably at axis-aligned tangents.
        def sum(*terms)
          value = terms.sum
          Error.("Quadratic intersection coefficients are not finite") unless value.finite?
          value.abs <= 8 * Float::EPSILON * terms.sum(&:abs) ? 0.0 : value
        end
      end
    end
  end
end
