# frozen_string_literal: true

module Sevgi
  module Geometry
    class Element
      # Abstract family of circular and elliptical boundary elements.
      # Arc is open, while Ellipse and Circle have closed boundaries. Concrete values share exact and precision-aware comparisons.
      class Arced < self
        # Compares canonical fields with coordinate and numeric precision.
        # @param other [Object] comparison target
        # @param precision [Integer, nil] decimal precision, or nil for the current function default
        # @return [Boolean]
        def eq?(other, precision: nil)
          other.instance_of?(self.class) &&
            state.zip(other.send(:state)).all? do |left, right|
              left.is_a?(::Numeric) ? F.eq?(left, right, precision:) : left.eq?(right, precision:)
            end
        end

        # Reports strict equality by concrete class and canonical fields.
        # @param other [Object] comparison target
        # @return [Boolean]
        def eql?(other) = other.instance_of?(self.class) && state == other.send(:state)

        # Returns a hash independent of numeric precision.
        # @return [Integer]
        def hash = [self.class, *state].hash

        # Reports whether a point is outside the element.
        # @param point [Sevgi::Geometry::Point, Array<Numeric>] point to test
        # @return [Boolean]
        # @raise [Sevgi::Geometry::Error] when point cannot be coerced
        def outside?(point) = !inside?(point)

        alias == eql?
      end
    end
  end
end
