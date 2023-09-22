# frozen_string_literal: true

module Sevgi
  Dim = Data.define(:width, :height, :unit) do
    def initialize(width:, height:, unit: "mm") = super(width: Float(width), height: Float(height), unit:)

    def longest  = deconstruct.max

    def rect     = Geometry::Rect[width, height]

    def shortest = deconstruct.min
  end
end
