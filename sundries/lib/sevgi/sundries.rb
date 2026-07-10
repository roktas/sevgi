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
  # This component loads its eager public surfaces directly. `Ruler`, `Tile`, and `Grid` therefore require
  # `sevgi-function`, `sevgi-geometry`, and `sevgi-graphics` as runtime dependencies of the `sevgi-sundries` gem.
  module Sundries
  end
end
