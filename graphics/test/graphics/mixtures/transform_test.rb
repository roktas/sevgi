# frozen_string_literal: true

require_relative "../../test_helper"
require "bigdecimal"

module Sevgi
  module Graphics
    module Mixtures
      class TransformTest < Minitest::Test
        Number = Class.new(::Numeric) do
          def initialize(value)
            super()
            @value = value
          end

          def to_f = @value.to_f
        end

        def test_transform_methods_append_operations
          element = SVG do
            rect
              .Rotate(45, 1, 2)
              .Scale(2, 3)
              .Scale(4)
              .SkewX(10)
              .SkewY(20)
              .Translate(5, 6)
              .TranslateX(7)
              .TranslateY(8)
              .Matrix(1, 0, 0, 1, 7, 8)
          end
            .children
            .first

          [
            "rotate(45, 1, 2) scale(2, 3) scale(4) skewX(10) skewY(20) translate(5 6) translate(7) translate(0 8) matrix(1 0 0 1 7 8)",
            element[:transform]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_transform_methods_keep_semantic_zero_values
          element = SVG do
            rect.Scale(0).Matrix(0, 0, 0, 0, 0, 0)
          end
            .children
            .first

          assert_equal("scale(0) matrix(0 0 0 0 0 0)", element[:transform])
        end

        def test_transforms_render_normalized_svg_numbers
          element = SVG do
            rect
              .Rotate(Rational(1, 2), BigDecimal("1"), Number.new(2))
              .Scale(BigDecimal("1.5"), Rational(2, 1))
              .SkewX(Rational(1, 2))
              .SkewY(BigDecimal("1.5"))
              .Translate(Number.new(2), Rational(1, 2))
              .Matrix(9_007_199_254_740_993, 0.0, Rational(1, 2), BigDecimal("1.5"), Number.new(2), 0)
          end
            .children
            .first

          assert_equal(
            "rotate(0.5, 1, 2) scale(1.5, 2) skewX(0.5) skewY(1.5) " \
              "translate(2 0.5) matrix(9007199254740993 0 0.5 1.5 2 0)",
            element[:transform]
          )
        end

        def test_transform_methods_skip_identity_operations
          element = SVG do
            rect.Rotate(0).SkewX(0).SkewY(0).Translate(0).TranslateX(0).TranslateY(0)
          end
            .children
            .first

          assert_nil(element[:transform])
        end

        def test_axis_translation_helpers_validate_operands
          element = SVG { rect }.children.first

          ["oops", Complex(1, 2), Float::INFINITY, Float::NAN].each do |value|
            assert_raises(Sevgi::ArgumentError) { element.TranslateX(value) }
            assert_raises(Sevgi::ArgumentError) { element.TranslateY(value) }
            assert_nil(element[:transform])
          end
        end

        def test_transform_methods_validate_arguments
          element = SVG { rect }.children.first

          assert_raises(ArgumentError) { element.Rotate(10, 1) }
          assert_raises(ArgumentError) { element.Matrix(1, 2, 3) }
        end

        def test_transforms_reject_non_finite_real_operands
          element = SVG { rect }.children.first
          invalid = ["oops", Complex(1, 2), Float::INFINITY, Float::NAN]
          operations = {
            matrix: -> (value) { element.Matrix(value, 0, 0, 1, 0, 0) },
            rotate: -> (value) { element.Rotate(value) },
            rotation_origin: -> (value) { element.Rotate(1, value, 0) },
            scale: -> (value) { element.Scale(value) },
            scale_y: -> (value) { element.Scale(1, value) },
            skew_x: -> (value) { element.Skew(value, 0) },
            skew_y: -> (value) { element.Skew(0, value) },
            skew_x_axis: -> (value) { element.SkewX(value) },
            skew_y_axis: -> (value) { element.SkewY(value) },
            translate: -> (value) { element.Translate(value) },
            translate_y: -> (value) { element.Translate(0, value) }
          }

          invalid.product(operations.values).each do |value, operation|
            assert_raises(Sevgi::ArgumentError) { operation.call(value) }
            assert_nil(element[:transform])
          end

          operations.except(:scale_y, :translate_y).each_value do |operation|
            assert_raises(Sevgi::ArgumentError) { operation.call(nil) }
            assert_nil(element[:transform])
          end
        end

        def test_align_rejects_non_finite_box_dimensions
          element = SVG { rect }.children.first
          box = Data.define(:width, :height)

          [box.new(Float::INFINITY, 1), box.new(1, "oops")].each do |invalid|
            assert_raises(Sevgi::ArgumentError) { element.Align(:center, inner: invalid, outer: box.new(2, 2)) }
            assert_nil(element[:transform])
          end
        end

        def test_align_centers_inner_box_in_outer_box
          element = SVG do
            rect.Align(:center, inner: Canvas.(width: 20, height: 10), outer: Canvas.(width: 30, height: 40))
          end
            .children
            .first

          assert_equal("translate(5 15)", element[:transform])
        end

        def test_flip_y_scales_y_axis_by_negative_one
          element = SVG do
            rect.FlipY()
          end
            .children
            .first

          assert_equal("scale(1, -1)", element[:transform])
        end

        def test_flip_scales_both_axes_by_negative_one
          element = SVG do
            rect.Flip()
          end
            .children
            .first

          assert_equal("scale(-1, -1)", element[:transform])
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
