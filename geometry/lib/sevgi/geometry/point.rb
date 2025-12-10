# frozen_string_literal: true

module Sevgi
  module Geometry
    module Affinity
      def reflect(x: true, y: true)     = with(x: (y ? -1 : 1) * self.x, y: (x ? -1 : 1) * self.y)

      def reflect_x                     = with(y: -y)

      def reflect_y                     = with(x: -x)

      def rotate(a)                     = with(x: x * F.cos(a) - y * F.sin(a), y: x * F.sin(a) + y * F.cos(a))

      def scale(sx, sy = Undefined)     = with(x: sx * x, y: Undefined.default(sy, sx) * y)

      def skew(ax, ay = Undefined)      = with(x: x + y * F.tan(ax), y: y + x * F.tan(Undefined(ay, ax)))

      def skew_x(a)                     = with(x: x + y * f.tan(a))

      def skew_y(a)                     = with(y: y + x * F.tan(a))

      def translate(dx, dy = Undefined) = with(x: x + dx, y: y + Undefined.default(dy, dx))
    end

    Point = Data.define(:x, :y) do
      include Comparable
      include Affinity

      def self.angle(starting, ending)
        starting, ending = Tuples[Point, starting, ending]
        F.atan2(ending.y - starting.y, ending.x - starting.x)
      end

      def self.eq?(this, that, precision: nil)
        this, that = Tuples[self, this, that]
        F.eq?(this.x, that.x, precision:) && F.eq?(this.y, that.y, precision:)
      end

      def self.length(starting, ending)
        starting, ending = Tuples[Point, starting, ending]
        ::Math.sqrt((starting.y - ending.y) ** 2 + (starting.x - ending.x) ** 2)
      end

      def self.origin
        new(x: 0.0, y: 0.0)
      end

      def initialize(x:, y:)         = super(x: x.to_f, y: y.to_f)

      def <=>(other)                 = ((other = Tuple[Point, other]).nan? || self.nan?) ? nil : deconstruct <=> other.deconstruct

      def above?(other)              = y <= (other = Tuple[Point, other]).y

      def approx(precision = nil)    = with(x: F.approx(x, precision), y: F.approx(y, precision))

      def below?(other)              = y >= (other = Tuple[Point, other]).y

      def eq?(other, precision: nil) = self.class.eq?(self, other, precision:)

      def eql?(other)                = self.class == other.class && deconstruct == other.deconstruct

      def hash                       = [ self.class, *deconstruct ].hash

      def infinite?                  = deconstruct.any?(&:infinite?)

      def left?(other)               = x <= (other = Tuple[Point, other]).x

      def nan?                       = deconstruct.any?(&:nan?)

      def right?(other)              = x >= (other = Tuple[Point, other]).x

      def to_cs                      = "#{F.approx(x)},#{F.approx(y)}"

      def to_s                       = "(#{to_cs})"

      alias_method :==, :eql?
    end

    Origin = Point.origin
  end
end
