# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class TransformTest < Minitest::Test
        def test_transform_methods_append_operations
          element = SVG do
            rect
              .Rotate(45, 1, 2)
              .Scale(2, 3)
              .Scale(4)
              .SkewX(10)
              .SkewY(20)
              .Translate(5, 6)
              .Matrix(1, 0, 0, 1, 7, 8)
          end
            .children
            .first

          [
            "rotate(45, 1, 2) scale(2, 3) scale(4) skewX(10) skewY(20) translate(5 6) matrix(1 0 0 1 7 8)",
            element[:transform]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_transform_methods_skip_zero_operations
          element = SVG do
            rect.Rotate(0).Scale(0).SkewX(0).SkewY(0).Translate(0).Matrix(0, 0, 0, 0, 0, 0)
          end
            .children
            .first

          assert_nil(element[:transform])
        end

        def test_transform_methods_validate_arguments
          element = SVG { rect }.children.first

          assert_raises(ArgumentError) { element.Rotate(10, 1) }
          assert_raises(ArgumentError) { element.Matrix(1, 2, 3) }
        end

        def test_align_centers_inner_box_in_outer_box
          element = SVG do
            rect.Align(:center, inner: Canvas.(width: 20, height: 10), outer: Canvas.(width: 30, height: 40))
          end
            .children
            .first

          assert_equal("translate(5.0 15.0)", element[:transform])
        end

        def test_flip_y_scales_y_axis_by_negative_one
          element = SVG do
            rect.FlipY()
          end
            .children
            .first

          assert_equal("scale(1, -1)", element[:transform])
        end

        def test_transform_update_appends_operations
          element = SVG do
            rect.Translate(1).FlipY()
          end
            .children
            .first

          assert_equal("translate(1) scale(1, -1)", element[:transform])
        end
      end
    end
  end
end
