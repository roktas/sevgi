# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Sundries
    class RulerTest < Minitest::Test
      def test_interval_construction_success
        il = Interval.new(3, 4)

        [
          12.0,                         il.d,
          2.0,                          il.count(5),
          3,                            il.u,
          4,                            il.n,
          6.0,                          il.h,
          9.0,                          il[3],
          il.d,                         il.length,

          [ 0.0, 3.0, 6.0, 9.0, 12.0 ], il.ds,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_interval_construction_failure
        assert_raises(NoMethodError) { Interval.new(Object.new, 4) }
      end

      def test_ruler_without_waste
        r = Ruler.new(unit: 1.0, multiple: 10, brut: 150.0)

        assert(r.sub.is_a?(Interval))

        [
          0.0,       r.margin,
          0.0,       r.waste,
          10.0,      r.u,
          15,        r.n,
          150.0,     r.d,
          75.0,      r.h,
          r.d,       r.length,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_ruler_sub
        r = Ruler.new(unit: 1.0, multiple: 10, brut: 150.0)

        assert(r.sub.is_a?(Interval))

        [
          1.0,       r.sub.u,
          10,        r.sub.n,
          10.0,      r.sub.d,
          3.0,       r.sub[3],
          5.0,       r.sub.h,
          r.sd,      r.sub.d,
          r.su,      r.sub.u,
          r.sub.d,   r.sub.length,

          [
            0.0, 1.0, 2.0, 3.0, 4.0, 5.0,
            6.0, 7.0, 8.0, 9.0, 10.0
          ],         r.sub.ds,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_ruler_with_waste
        r = Ruler.new(unit: 1.0, multiple: 10, brut: 195.0, margin: 15)

        [
          10.0,      r.u,
          16,        r.n,
          160.0,     r.d,
          17.5,      r.margin,
          35.0,      r.waste,
          80.0,      r.h,
          r.d,       r.length,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_ruler_even_with_waste
        r = RulerEven.new(unit: 1.0, multiple: 10, brut: 195.0, margin: 18)

        [
          10.0,      r.u,
          14,        r.n,
          140.0,     r.d,
          27.5,      r.margin,
          55.0,      r.waste,
          70.0,      r.h,
          r.d,       r.length,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_ruler_expand
        r = Ruler.new(unit: 1.0, multiple: 10, brut: 195.0, margin: 15).expand

        assert(r.is_a?(Ruler))
        assert(r.sub.is_a?(Interval))

        [
          1.0,       r.u,
          1.0,       r[1],
          160,       r.n,
          160.0,     r.d,
          80.0,      r.h,
          r.d,       r.length,

          [
              0.0,   1.0,   2.0,   3.0,   4.0,   5.0,   6.0,   7.0,   8.0,   9.0,  10.0,  11.0,  12.0,  13.0,  14.0,  15.0,  16.0,  17.0,  18.0,  19.0,
             20.0,  21.0,  22.0,  23.0,  24.0,  25.0,  26.0,  27.0,  28.0,  29.0,  30.0,  31.0,  32.0,  33.0,  34.0,  35.0,  36.0,  37.0,  38.0,  39.0,
             40.0,  41.0,  42.0,  43.0,  44.0,  45.0,  46.0,  47.0,  48.0,  49.0,  50.0,  51.0,  52.0,  53.0,  54.0,  55.0,  56.0,  57.0,  58.0,  59.0,
             60.0,  61.0,  62.0,  63.0,  64.0,  65.0,  66.0,  67.0,  68.0,  69.0,  70.0,  71.0,  72.0,  73.0,  74.0,  75.0,  76.0,  77.0,  78.0,  79.0,
             80.0,  81.0,  82.0,  83.0,  84.0,  85.0,  86.0,  87.0,  88.0,  89.0,  90.0,  91.0,  92.0,  93.0,  94.0,  95.0,  96.0,  97.0,  98.0,  99.0,
            100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0, 107.0, 108.0, 109.0, 110.0, 111.0, 112.0, 113.0, 114.0, 115.0, 116.0, 117.0, 118.0, 119.0,
            120.0, 121.0, 122.0, 123.0, 124.0, 125.0, 126.0, 127.0, 128.0, 129.0, 130.0, 131.0, 132.0, 133.0, 134.0, 135.0, 136.0, 137.0, 138.0, 139.0,
            140.0, 141.0, 142.0, 143.0, 144.0, 145.0, 146.0, 147.0, 148.0, 149.0, 150.0, 151.0, 152.0, 153.0, 154.0, 155.0, 156.0, 157.0, 158.0, 159.0,
            160.0
          ],         r.ds,
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
