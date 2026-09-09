# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class CallGuardTest < Minitest::Test
        def test_call_rejects_unchanged_recursive_invocation
          mod = ::Module.new
          mod.extend(Graphics::Module)
          mod.module_eval do
            define_method(:call) do |depth|
              Call(mod, depth)
            end
          end

          doc = SVG(:minimal)
          error = assert_raises(Sevgi::ArgumentError) { doc.Call(mod, 1) }

          assert_match(/Recursive callable invocation/, error.message)
          assert_match(/unchanged arguments/, error.message)
          assert_empty(doc.children)
        end

        def test_call_allows_recursive_invocation_when_arguments_change
          mod = ::Module.new
          mod.extend(Graphics::Module)
          mod.module_eval do
            define_method(:call) do |depth|
              rect(id: depth.to_s)
              Call(mod, depth - 1) if depth.positive?
            end
          end

          doc = SVG(:minimal)
          doc.Call(mod, 2)

          assert_equal(%w[2 1 0], doc.children.map { it[:id] })
        end

        def test_call_guard_cleans_up_after_failure
          recursive = ::Module.new
          recursive.extend(Graphics::Module)
          recursive.module_eval do
            define_method(:call) { Call(recursive) }
          end

          assert_raises(Sevgi::ArgumentError) { SVG(:minimal).Call(recursive) }

          ordinary = ::Module.new do
            extend(Graphics::Module)

            def call = rect(id: "ok")
          end
          doc = SVG(:minimal)
          doc.Call(ordinary)

          assert_equal(["ok"], doc.children.map { it[:id] })
        end
      end
    end
  end
end
