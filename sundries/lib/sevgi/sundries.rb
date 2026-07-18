# frozen_string_literal: true

require "sevgi/function"
require "sevgi/geometry"
require "sevgi/graphics"

require_relative "sundries/ruler"
require_relative "sundries/tile"
require_relative "sundries/grid"

require_relative "sundries/export"

require_relative "sundries/version"

module Sevgi
  # Layout, tiling, grid, and export helpers shared by Sevgi consumers.
  #
  # {Ruler} fits repeatable distances into a span; {Grid} combines two rulers
  # and exposes drawable lines; {Tile} repeats geometry by rows and columns.
  # These layout values can be computed without an SVG document and then passed
  # to Graphics. Native PDF/PNG dependencies remain lazy and are loaded only by
  # {Export}.
  # @example Load the component and build a tiled geometry layout
  #   require "sevgi/sundries"
  #
  #   cell = Sevgi::Geometry::Rect[8, 4]
  #   Sevgi::Sundries::Tile.new(cell, nx: 3, ny: 2).box.deconstruct
  # @see Sevgi::Graphics::Canvas
  module Sundries
  end
end
