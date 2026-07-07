# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelSundriesTest < Minitest::Test
    def test_grid_builds_sundries_grid_from_canvas
      receiver = Module.new.extend(::Sevgi)
      canvas = Graphics::Canvas.from_paper(:a4, margins: [10, 20])
      grid = receiver.Grid(canvas, unit: 5, multiple: 2)

      [
        210.0,
        grid.x.brut,
        297.0,
        grid.y.brut,
        20.0,
        grid.x.margin,
        13.5,
        grid.y.margin
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
    end

    def test_grid_rejects_non_canvas
      receiver = Module.new.extend(::Sevgi)

      error = assert_raises(ArgumentError) do
        receiver.Grid(Object.new, unit: 5, multiple: 2)
      end

      assert_match(/Must be a Canvas/, error.message)
    end
  end
end
