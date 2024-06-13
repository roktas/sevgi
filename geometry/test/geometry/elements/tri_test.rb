# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class TriTest < Minitest::Test
      def test_tri_construction
        tri = Tri[
          [ 5.0, F.atan2(4.0, 3.0) ],
          [ 4.0, 270.0             ],
        ]

        [
          5.0, tri.AB.l,
          4.0, tri.BC.l,
          3.0, tri.CA.l,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
