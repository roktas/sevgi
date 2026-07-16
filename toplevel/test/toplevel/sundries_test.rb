# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelSundriesTest < Minitest::Test
    def test_grid_builds_sundries_grid_from_canvas
      receiver = ::Module.new.extend(::Sevgi)
      canvas = Graphics::Canvas.call(width: 210, height: 297, unit: :px, name: :poster, margins: [10, 20])
      grid = receiver.Grid(canvas, unit: 5, multiple: 2)

      [
        210.0,
        grid.x.brut,
        297.0,
        grid.y.brut,
        20.0,
        grid.x.start,
        13.5,
        grid.y.start,
        :px,
        grid.canvas.unit,
        :poster,
        grid.canvas.name
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
    end

    def test_grid_preserves_canvas_margin_shorthands
      receiver = ::Module.new.extend(::Sevgi)
      [
        [[], [0.0, 0.0, 0.0, 0.0]],
        [[10], [10.0, 10.0, 10.0, 10.0]],
        [[10, 20], [10.0, 20.0, 10.0, 20.0]],
        [[10, 20, 30], [10.0, 20.0, 30.0, 20.0]],
        [[10, 20, 30, 5], [10.0, 22.5, 30.0, 7.5]]
      ].each do |margins, expected|
        canvas = Graphics::Canvas.call(width: 100, height: 100, margins:)
        grid = receiver.Grid(canvas, unit: 10, multiple: 1)

        assert_equal(expected, grid.canvas.margin.to_a)
        assert_equal(grid.x.brut, grid.x.start + grid.width + grid.x.finish)
        assert_equal(grid.y.brut, grid.y.start + grid.height + grid.y.finish)
      end
    end

    def test_grid_rejects_an_inner_area_without_an_interval
      receiver = ::Module.new.extend(::Sevgi)
      canvas = Graphics::Canvas.call(width: 25, height: 25, margins: [10])

      error = assert_raises(ArgumentError) { receiver.Grid(canvas, unit: 10, multiple: 1) }

      assert_match(/fit at least one interval/, error.message)
    end

    def test_grid_rejects_non_canvas
      receiver = ::Module.new.extend(::Sevgi)

      error = assert_raises(ArgumentError) do
        receiver.Grid(Object.new, unit: 5, multiple: 2)
      end

      assert_match(/Must be a Canvas/, error.message)
    end

    def test_grid_rejects_invalid_ruler_inputs
      receiver = ::Module.new.extend(::Sevgi)
      canvas = Graphics::Canvas.from_paper(:a4)

      [
        [/Ruler unit must be positive/, {unit: 0, multiple: 2}],
        [/Ruler multiple must be a positive Integer/, {unit: 5, multiple: 1.5}]
      ].each do |message, kwargs|
        error = assert_raises(ArgumentError) { receiver.Grid(canvas, **kwargs) }

        assert_match(message, error.message)
      end
    end
  end
end
