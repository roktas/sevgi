# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class RectTest < Minitest::Test
      include Fixtures

      def test_rect_inside
        assert(segment345.rect.inside?(Point[1, 1]))
      end

      def test_rect_onto
        assert(segment345.rect.onto?(Point[3, 0]))
      end

      def test_rect_outside
        assert(segment345.rect.outside?(Point[5, 0]))
      end
    end
  end
end
