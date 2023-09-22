# frozen_string_literal: true

module Sevgi
  module Function
    module Float
      @precision = PRECISION = 6

      class << self
        attr_accessor :precision
      end

      def approx(float, precision = nil)   = float.round(precision || Function::Float.precision)

      def eq?(left, right, precision: nil) = approx(left, precision) == approx(right, precision)

      def ge?(left, right, precision: nil) = approx(left, precision) >= approx(right, precision)

      def gt?(left, right, precision: nil) = approx(left, precision) > approx(right, precision)

      def le?(left, right, precision: nil) = approx(left, precision) <= approx(right, precision)

      def lt?(left, right, precision: nil) = approx(left, precision) < approx(right, precision)

      def nonzero?(...)                    = !zero?(...)

      def prettify(*args)                  = args.map { (i = _1.to_i) == _1.to_f ? i : _1 }

      def round(float, precision)          = precision ? float.round(precision) : float

      def zero?(value, precision: nil)     = eq?(value, 0.0, precision:)
    end

    extend Float
  end
end
