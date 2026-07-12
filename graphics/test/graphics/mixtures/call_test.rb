# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class CallTest < Minitest::Test
        def test_call_discovers_all_public_entry_points
          included = ::Module.new do
            def included_item
              rect(id: "included")
            end
          end

          mod = ::Module.new do
            def early
              rect(id: "early")
            end

            extend(Graphics::Module)
            include(included)

            def late
              rect(id: "late")
            end
          end

          doc = SVG(:minimal)
          doc.Call(mod)

          assert_equal(%w[included early late], doc.children.map { it[:id] })
        end

        def test_callable_module_exposes_only_dsl_surface
          mod = ::Module.new { extend(Graphics::Module) }

          assert_respond_to(mod, :base)
          refute_respond_to(mod, :method_added)
          %i[bases call callables extended].each { refute_respond_to(Graphics::Module, it) }
          %i[_bases _callables].each { refute_respond_to(mod, it) }
        end

        def test_call_runs_bases_and_public_methods
          mod = ::Module.new do
            extend(Graphics::Module)

            base { rect(id: "base-1") }
            base { rect(id: "base-2") }

            def call(id)
              rect(id:)
            end
          end

          doc = SVG(:minimal)
          result = doc.Call(mod, "main")

          [
            %w[base-1 base-2 main],
            doc.children.map { it[:id] },
            "main",
            result[:id]
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_base_requires_block
          mod = ::Module.new { extend(Graphics::Module) }

          assert_raises(ArgumentError) { mod.base }
        end

        def test_call_runs_base_without_public_methods
          mod = ::Module.new do
            extend(Graphics::Module)

            base { rect(id: "base") }
          end

          doc = SVG(:minimal)

          assert_nil(doc.Call(mod))
          assert_equal(["base"], doc.children.map { it[:id] })
        end

        def test_call_runs_diamond_base_once
          foundation = ::Module.new do
            extend(Graphics::Module)

            base { rect(id: "base") }
          end

          left = ::Module.new do
            extend(Graphics::Module)
            include(foundation)
          end

          right = ::Module.new do
            extend(Graphics::Module)
            include(foundation)
          end

          mod = ::Module.new do
            extend(Graphics::Module)
            include(left)
            include(right)

            def call
              rect(id: "call")
            end
          end

          doc = SVG(:minimal)
          doc.Call(mod)

          assert_equal(%w[base call], doc.children.map { it[:id] })
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

            base { rect(id: "parent-base") }

            def parent_item
              rect(id: "parent")
            end
          end

          child = ::Module.new do
            extend(Graphics::Module)
            include(parent)

            base { rect(id: "child-base") }

            def child_item
              rect(id: "child")
            end
          end

          doc = SVG(:minimal)
          doc.Call(child)

          assert_equal(%w[parent-base child-base parent child], doc.children.map { it[:id] })
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
