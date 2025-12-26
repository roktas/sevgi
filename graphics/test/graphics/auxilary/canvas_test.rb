# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    class CanvasTest < Minitest::Test
      def test_canvas_with_origin
        canvas = Canvas.(:a4, margins: [ 3, 5 ])

        [
          210.0 - 2 * 5.0, canvas.inner.width,
          297.0 - 2 * 3.0, canvas.inner.height,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
