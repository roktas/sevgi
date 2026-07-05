# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class CallTest < Minitest::Test
        def test_call_runs_hooks_and_public_methods
          mod = ::Module.new do
            extend(Graphics::Module)

            call { rect(id: "before") }
            call(true) { rect(id: "after") }

            def item(id)
              rect(id:)
            end
          end

          doc = SVG(:minimal)
          result = doc.Call(mod, "main")

          [
            %w[before main after],
            doc.children.map { it[:id] },
            "main",
            result[:id]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_call_rejects_non_module_argument
          assert_raises(ArgumentError) { SVG(:minimal).Call(Object.new) }
        end
      end
    end
  end
end
