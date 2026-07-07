# frozen_string_literal: true

require "sevgi/sundries"

module Sevgi
  module Toplevel
    # Builds a drawable grid from a graphics canvas.
    # @param canvas [Sevgi::Graphics::Canvas] canvas defining page size and margins
    # @param unit [Numeric] minor grid unit
    # @param multiple [Numeric] number of minor units in each major interval
    # @return [Sevgi::Sundries::Grid] grid fitted to the canvas
    # @raise [Sevgi::ArgumentError] when canvas, unit, multiple, or fitting span is invalid
    def Grid(canvas, unit:, multiple:)
      ArgumentError.("Must be a Canvas: #{canvas}") unless canvas.is_a?(Graphics::Canvas)

      Sundries::Grid[
        Sundries::Ruler.new(brut: canvas.width, unit:, multiple:, margin: canvas.left),
        Sundries::Ruler.new(brut: canvas.height, unit:, multiple:, margin: canvas.top)
      ]
    end

    promote Sundries::Export
  end
end
