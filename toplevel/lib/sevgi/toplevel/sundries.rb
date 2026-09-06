# frozen_string_literal: true

require "sevgi/sundries"

module Sevgi
  module Toplevel
    # Fits major and minor intervals into a span without drawing SVG elements.
    # @overload Ruler(brut:, unit:, multiple:, margins: [0.0])
    #   @param brut [Numeric] full available span
    #   @param unit [Numeric] minor interval length
    #   @param multiple [Integer] minor intervals per major interval
    #   @param margins [Array<Numeric>] one symmetric or two start/end minimum margins
    #   @return [Sevgi::Sundries::Ruler] fitted ruler
    #   @raise [Sevgi::ArgumentError] when the span, intervals, or margins are invalid
    # @see Sevgi::Sundries::Ruler#initialize
    def Ruler(...) = Sundries::Ruler.new(...)

    # Builds a drawable grid fitted inside a graphics canvas.
    #
    # The canvas margins are minimum clearances. Any span left after fitting
    # whole major intervals is shared equally between the opposite margins, so
    # their requested difference is preserved. The returned grid starts at
    # `(0, 0)`. {Sevgi::Sundries::Grid#canvas} exposes the fitted page margins.
    # @param canvas [Sevgi::Graphics::Canvas] canvas defining page size and margins
    # @param unit [Numeric] minor grid unit
    # @param multiple [Integer] number of minor units in each major interval
    # @return [Sevgi::Sundries::Grid] grid fitted to the canvas
    # @raise [Sevgi::ArgumentError] when canvas is not a graphics canvas
    # @raise [Sevgi::ArgumentError] when unit is not a finite positive number
    # @raise [Sevgi::ArgumentError] when multiple is not a positive integer
    # @raise [Sevgi::ArgumentError] when canvas dimensions, margins, and grid intervals cannot fit
    # @see Sevgi.Grid
    # @see Sevgi::Sundries::Grid
    def Grid(canvas, unit:, multiple:)
      ArgumentError.("Must be a Canvas: #{canvas}") unless canvas.is_a?(Graphics::Canvas)

      Sundries::Grid.new(
        x: Sundries::Ruler.new(brut: canvas.width, unit:, multiple:, margins: [canvas.left, canvas.right]),
        y: Sundries::Ruler.new(brut: canvas.height, unit:, multiple:, margins: [canvas.top, canvas.bottom]),
        canvas:
      )
    end

    promote Sundries::Export
  end
end
