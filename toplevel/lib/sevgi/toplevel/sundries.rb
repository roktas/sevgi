# frozen_string_literal: true

require "sevgi/sundries"

module Sevgi
  module Toplevel
    # Builds a drawable grid from a graphics canvas.
    # @param canvas [Sevgi::Graphics::Canvas] canvas defining page size and margins
    # @param unit [Numeric] minor grid unit
    # @param multiple [Integer] number of minor units in each major interval
    # @return [Sevgi::Sundries::Grid] grid fitted to the canvas
    # @raise [Sevgi::ArgumentError] when canvas is not a graphics canvas
    # @raise [Sevgi::ArgumentError] when unit is not a finite positive number
    # @raise [Sevgi::ArgumentError] when multiple is not a positive integer
    # @raise [Sevgi::ArgumentError] when canvas dimensions, margins, and grid intervals cannot fit
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
