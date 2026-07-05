# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class LintTest < Minitest::Test
        def test_lint_rejects_duplicate_ids
          error = assert_raises(LintError) do
            SVG(:minimal) do
              rect(id: "same")
              circle(id: "same")
            end
              .()
          end

          assert_match(/\bsame\b/, error.message)
        end

        def test_lint_can_be_disabled_for_call
          actual = SVG(:minimal) do
            rect(id: "same")
            circle(id: "same")
          end
            .(lint: false)

          assert_match(%r{<rect id="same"/>}, actual)
        end
      end
    end
  end
end
