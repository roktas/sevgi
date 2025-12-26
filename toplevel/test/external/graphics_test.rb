# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelGraphicsTest < Minitest::Test
    def test_external_graphics_canvas
      assert(SVG.is_a?(::Module))
      assert_equal(SVG, Graphics)
    end
  end
end
