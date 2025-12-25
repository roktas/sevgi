# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class ElementTest < Minitest::Test
      def test_element_construction_usual
        # rect = Rect.new(position: Point[1, 2], width: 3, height: 4)
        #
        # [
        #   1.0,            rect.position.x,
        #   2.0,            rect.position.y,
        #
        #   rect345.width,  rect.width,
        #   rect345.height, rect.height
        # ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
