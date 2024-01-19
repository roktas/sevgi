# frozen_string_literal: true

module Sevgi
  module Geometry
    Point = Data.define(:x, :y) do
      include Comparable

      def initialize(x:, y:)
        super(x: x.to_f, y: y.to_f)
      end

      def above?(other)
        y <= other.y
      end

      def below?(other)
        y >= other.y
      end

      def approx(precision = nil)
        with(x: F.approx(x, precision), y: F.approx(y, precision))
      end

      def eq?(other, precision: nil)
        self.class.eq?(self, other, precision:)
      end

      def infinite?
        [ x, y ].any?(&:infinite?)
      end

      def nan?
        [ x, y ].any?(&:nan?)
      end

      def to_s
        "P(#{F.approx(x)} #{F.approx(y)})"
      end

      def translate(dx: nil, dy: nil)
        with(x: x + (dx || 0.0), y: y + (dy || 0.0))
      end

      def unordered_between?(p, q)
        nan? ? false : between?([ p, q ].min, [ p, q ].max)
      end

      def <=>(other)
        return unless other.is_a?(self.class)
        return if other.nan? || nan?

        deconstruct <=> other.deconstruct
      end

      class << self
        def eq?(p, q, precision: nil) = F.eq?(p.x, q.x, precision:) && F.eq?(p.y, q.y, precision:)

        def origin                    = new(x: 0.0, y: 0.0)
      end
    end
  end
end
