# frozen_string_literal: true

module Sevgi
  module Geometry
    class Element
      def bbox = raise(NotImplementedError, "Instance method required: bbox")

      def ignorable?(precision = nil) = bbox.zero?(precision)
    end

    class BBox
      BBoxError = Class.new(GeometryError)

      attr_reader :ne, :sw

      def initialize(ne:, sw:)   = (@ne, @sw = ne, sw)

      def height                 = @height ||= F.height(ne, sw)

      def to_s                   = "[#{width}x#{height}]@[#{ne} ↘ #{sw}]"

      def width                  = @width ||= F.width(ne, sw)

      def zero?(precision = nil) = Point.eq?(ne, sw, precision:)

      private

      def validate!
        BBoxError.("North-East is not to the left of South-West: #{self}") if ne > sw
        BBoxError.("North-East is not below South-West: #{self}")          unless ne.below?(sw)
      end

      class << self
        def [](*points) = new(ne: points.min, sw: points.max)
      end
    end
  end
end

require_relative "elements/segment"
require_relative "elements/rect"
