# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class ParmTest < Minitest::Test
      def test_parm_construction
        parm = Parm[
          [ 2.0,              -15.0 ],
          [ 5.0, -F.atan2(4.0, 3.0) ],
        ]

        [
          2.0, parm.AB.l,
          5.0, parm.BC.l,
          2.0, parm.CD.l,
          5.0, parm.DA.l,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
