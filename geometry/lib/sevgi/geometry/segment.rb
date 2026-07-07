# frozen_string_literal: true

module Sevgi
  module Geometry
    Segment = Data.define(:length, :angle) do
      include Comparable

      def self.call(starting, ending)
        starting, ending = Tuples[Point, starting, ending]
        self[Point.length(starting, ending), Point.angle(starting, ending)]
      end

      def self.eq?(this, that, precision: nil)
        this, that = Tuples[self, this, that]
        F.eq?(this.length, that.length, precision:) && F.eq?(this.angle, that.angle, precision:)
      end

      def self.downward(length) = self[length, 90.0]
      def self.leftward(length) = self[length, 180.0]
      def self.rightward(length) = self[length, 0.0]
      def self.upward(length) = self[length, -90.0]

      class << self
        alias_method :horizontal, :rightward
        alias_method :vertical, :downward
      end

      def initialize(length:, angle:) = super(length: length.to_f, angle: angle.to_f)

      def <=>(other) = (other = Tuple[Segment, other]).nan? || nan? ? nil : length <=> other.length

      def approx(precision = nil) = with(length: F.approx(length, precision), angle: F.approx(angle, precision))

      def ending(starting) = Tuple[Point, starting].translate(x, y)

      def eq?(other, precision: nil) = self.class.eq?(self, other, precision:)

      def eql?(other) = self.class == other.class && deconstruct == other.deconstruct

      def hash = [self.class, *deconstruct].hash

      def infinite? = deconstruct.any?(&:infinite?)

      def line(point = Origin) = Line[length, angle, position: Tuple[Point, point]]

      def nan? = deconstruct.any?(&:nan?)

      def reverse = with(angle: angle + 180.0)

      def x = length * F.cos(angle)

      def y = length * F.sin(angle)
    end

    Polar = Data.define(:length, :angle)
  end
end
