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

        def test_call_skips_non_public_methods
          mod = ::Module.new do
            extend(Graphics::Module)

            def item
              rect(id: "public")
            end

            def helper
              rect(id: "private")
            end

            def utility
              rect(id: "protected")
            end

            private(:helper)
            protected(:utility)
          end

          doc = SVG(:minimal)
          doc.Call(mod)

          assert_equal(["public"], doc.children.map { it[:id] })
        end

        def test_call_runs_redefined_method_once
          verbose = $VERBOSE

          mod = begin
            $VERBOSE = nil

            ::Module.new do
              extend(Graphics::Module)

              def item
                rect(id: "old")
              end

              def item
                rect(id: "new")
              end
            end

          ensure
            $VERBOSE = verbose
          end

          doc = SVG(:minimal)
          doc.Call(mod)

          assert_equal(["new"], doc.children.map { it[:id] })
        end

        def test_call_skips_removed_methods
          mod = ::Module.new do
            extend(Graphics::Module)

            def item
              rect(id: "removed")
            end

            remove_method(:item)
          end

          doc = SVG(:minimal)
          doc.Call(mod)

          assert_empty(doc.children)
        end

        def test_call_runs_inherited_methods_parent_first
          parent = ::Module.new do
            extend(Graphics::Module)

            def parent_item
              rect(id: "parent")
            end
          end

          child = ::Module.new do
            extend(Graphics::Module)
            include(parent)

            def child_item
              rect(id: "child")
            end
          end

          doc = SVG(:minimal)
          doc.Call(child)

          assert_equal(%w[parent child], doc.children.map { it[:id] })
        end

        def test_call_preserves_definition_order
          mod = ::Module.new do
            extend(Graphics::Module)

            def first
              rect(id: "first")
            end

            def second
              rect(id: "second")
            end
          end

          doc = SVG(:minimal)
          doc.Call(mod)

          assert_equal(%w[first second], doc.children.map { it[:id] })
        end

        def test_call_rejects_non_module_argument
          assert_raises(ArgumentError) { SVG(:minimal).Call(Object.new) }
        end
      end
    end
  end
end
