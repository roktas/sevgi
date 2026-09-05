# frozen_string_literal: true

module Sevgi
  module Geometry
    class Ellipse
      # Bounded adaptive Simpson integration of elliptical arc speed.
      # Radii are scaled before integration to keep the integrand finite.
      # @api private
      class Length
        ABSOLUTE_ERROR = 1e-9
        EVALUATIONS = 65_536
        RELATIVE_ERROR = 1e-10

        def initialize(rx, ry)
          @scale = [rx, ry].max
          @rx, @ry = rx / @scale, ry / @scale
          @evaluations = 0
        end

        # rubocop:disable-next Metrics/AbcSize
        def integrate(starting_angle, extent)
          return 0.0 if extent.zero?

          @starting = F.to_radians((extent.negative? ? starting_angle + extent : starting_angle) % 360)
          span = F.to_radians(extent.abs)
          cuts = [0.0, *(1..8).map { (it * ::Math::PI / 2) - @starting }.select { it.positive? && it < span }, span]
          # Quarter-turn chords give a lower bound for relative error, including highly eccentric ellipses.
          lower_bound = cuts.each_cons(2).sum { |left, right| chord(left, right) }
          tolerance = (ABSOLUTE_ERROR / @scale) + (RELATIVE_ERROR * lower_bound)
          integral = cuts.each_cons(2).sum do |left, right|
            integrate_interval(left, right, tolerance * ((right - left) / span))
          end

          Real[:length, integral * @scale]
        end

        private

        def chord(left, right)
          left, right = @starting + left, @starting + right
          ::Math.hypot(@rx * (::Math.cos(right) - ::Math.cos(left)), @ry * (::Math.sin(right) - ::Math.sin(left)))
        end

        # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
        def integrate_interval(left, right, tolerance)
          fa, fm, fb = [left, (left + right) / 2, right].map { speed(it) }
          stack = [[left, right, fa, fm, fb, simpson(left, right, fa, fm, fb), tolerance]]
          integral = 0.0
          until stack.empty?
            a, b, fa, fm, fb, whole, error = stack.pop
            middle = (a + b) / 2
            fl, fr = speed((a + middle) / 2), speed((middle + b) / 2)
            lower, upper = simpson(a, middle, fa, fl, fm), simpson(middle, b, fm, fr, fb)
            correction = lower + upper - whole
            if correction.abs <= 15 * error
              integral += lower + upper + (correction / 15)
            else
              Error.("Ellipse length cannot converge at floating-point precision") if middle == a || middle == b
              stack << [middle, b, fm, fr, fb, upper, error / 2]
              stack << [a, middle, fa, fl, fm, lower, error / 2]
            end
          end

          integral
        end

        def simpson(left, right, first, middle, last) = (right - left) * (first + (4 * middle) + last) / 6

        def speed(offset)
          @evaluations += 1
          Error.("Ellipse length exceeded #{EVALUATIONS} evaluations") if @evaluations > EVALUATIONS
          angle = @starting + offset
          ::Math.hypot(@rx * ::Math.sin(angle), @ry * ::Math.cos(angle))
        end
      end

      private_constant :Length
    end
  end
end
