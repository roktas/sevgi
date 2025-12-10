# frozen_string_literal: true

require "sevgi/sundries"

module Sevgi
  module External
    def Grid(canvas, unit:, multiple:)
      ArgumentError.("Must be a Canvas: #{canvas}") unless canvas.is_a?(Graphics::Canvas)

      Sundries::Grid[
        Sundries::Ruler.new(brut: canvas.width,  unit:, multiple:, margin: canvas.left),
        Sundries::Ruler.new(brut: canvas.height, unit:, multiple:, margin: canvas.top)
      ]
    end

    Promote Sundries::Printer
  end
end
