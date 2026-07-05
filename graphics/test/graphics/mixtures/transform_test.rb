# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class TransformTest < Minitest::Test
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
