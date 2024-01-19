# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Utensils
    class RulerTest < Minitest::Test
      def test_ruler_basics_with_odd_numbers
        ruler = Ruler.new(brut: 3, unit: 1, multiple: 2, minspace: 0.5)

        [
          2.0,             ruler.length,
          3,               ruler.l,
          [ 0.0, 1.0, 2.0 ], ruler.ls,
          2,               ruler.m,
          2.0,             ruler.major,
          1.0,             ruler.minor,
          3,               ruler.n,
          1.0,             ruler.space
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_ruler_basics_with_usual_numbers
        ruler = Ruler.new(brut: 10, unit: 2, multiple: 3, minspace: 0)

        [
          6.0,             ruler.length,
          3,               ruler.l,
          [ 0.0, 3.0, 6.0 ], ruler.ls,
          2,               ruler.m,
          6.0,             ruler.major,
          2.0,             ruler.minor,
          4,               ruler.n,
          4.0,             ruler.space
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
