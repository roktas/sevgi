# frozen_string_literal: true

module Sevgi
  module Utensils
    module External
      def Ruler(...)
        Ruler.new(...)
      end

      def Ts(canvas, unit:, multiple:)
        ArgumentError.("Must be a Canvas: #{canvas}") unless canvas.is_a?(Graphics::Canvas)

        Tsquare.new(
          hruler: Utensils::Ruler.new(brut: canvas.width,  unit:, multiple:, minspace: canvas.left),
          vruler: Utensils::Ruler.new(brut: canvas.height, unit:, multiple:, minspace: canvas.top),
        )
      end
    end

    extend External
  end
end
