# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class CallTest < Minitest::Test
        FrozenCallable = ::Module
          .new do
            extend(Graphics::Module)

            base { rect(id: "base") }

            def call(id)
              rect(id:)
            end
          end
          .freeze

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

        def test_call_preserves_module_method_lookup
          parent = ::Module.new do
            extend(Graphics::Module)

            base { base_item }

            def item
              rect(id: "parent")
            end

            private

            def base_item
              rect(id: "base")
            end

            def inherited_suffix
              children.size
            end
          end

          mod = ::Module.new do
            extend(Graphics::Module)
            include(parent)

            def item
              super
              raise "private helper missing" unless respond_to?(:inherited_suffix, true)

              helper
            end

            protected

            def helper
              rect(id: "child-#{inherited_suffix}")
            end
          end

          doc = SVG(:minimal)
          result = doc.Call(mod)

          assert_equal(%w[base parent child-2], doc.children.map { it[:id] })
          assert_same(doc.children.last, result)
          refute_respond_to(doc, :helper)
          refute_respond_to(doc.class, :item)
        end

        def test_call_maps_callable_self_back_to_receiver
          mod = ::Module.new do
            extend(Graphics::Module)

            def call = self
          end

          doc = SVG(:minimal)

          assert_same(doc, doc.Call(mod))
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

        def test_call_discovers_promoted_methods
          drawing = proc { rect(id: "promoted") }
          modules = [
            ::Module.new do
              extend(Graphics::Module)
              private

              define_method(:item, &drawing)

              public(:item)
            end,
            ::Module.new do
              private

              define_method(:item, &drawing)

              extend(Graphics::Module)
              public(:item)
            end
          ]

          modules.each do |mod|
            doc = SVG(:minimal)
            doc.Call(mod)

            assert_equal(["promoted"], doc.children.map { it[:id] })
          end
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

        def test_call_accepts_frozen_modules
          anonymous = ::Module
            .new do
              extend(Graphics::Module)

              def call(id)
                rect(id:)
              end
            end
            .freeze
          duplicated = FrozenCallable.dup.freeze

          [FrozenCallable, FrozenCallable, duplicated, anonymous].each_with_index do |mod, index|
            doc = SVG(:minimal)
            doc.Call(mod, index.to_s)

            expected = mod.equal?(anonymous) ? [index.to_s] : ["base", index.to_s]
            assert_equal(expected, doc.children.map { it[:id] })
          end
        end

        def test_call_accepts_concurrent_frozen_module
          results = 8
            .times
            .map do |index|
              Thread.new do
                doc = SVG(:minimal)
                doc.Call(FrozenCallable, index.to_s)
                doc.children.map { it[:id] }
              end
            end
            .map(&:value)

          assert_equal(8.times.map { ["base", it.to_s] }, results)
        end

        def test_dup_owns_callable_configuration
          original = ::Module.new do
            extend(Graphics::Module)

            base { rect(id: "original-base") }

            def call
              rect(id: "original-call")
            end
          end

          copy = original.dup

          copy.base { rect(id: "copy-base") }
          copy.module_eval do
            def extra
              rect(id: "copy-extra")
            end
          end

          original_doc = SVG(:minimal)
          copy_doc = SVG(:minimal)
          original_doc.Call(original)
          copy_doc.Call(copy)

          assert_equal(%w[original-base original-call], original_doc.children.map { it[:id] })
          assert_equal(
            %w[original-base copy-base original-call copy-extra],
            copy_doc.children.map { it[:id] }
          )
        end

        def test_clone_owns_callable_configuration
          original = ::Module.new do
            extend(Graphics::Module)

            base { rect(id: "original") }
          end

          copy = original.clone
          copy.base { rect(id: "copy") }

          original_doc = SVG(:minimal)
          copy_doc = SVG(:minimal)
          original_doc.Call(original)
          copy_doc.Call(copy)

          assert_equal(["original"], original_doc.children.map { it[:id] })
          assert_equal(%w[original copy], copy_doc.children.map { it[:id] })
        end

        def test_freeze_closes_callable_configuration
          original = ::Module.new do
            extend(Graphics::Module)

            base { rect(id: "original") }
          end

          original.freeze

          assert_raises(FrozenError) { original.base { rect(id: "late") } }
          assert_raises(FrozenError) { original.clone.base { rect(id: "late") } }

          [original.dup, original.clone(freeze: false)].each do |copy|
            copy.base { rect(id: "copy") }
            doc = SVG(:minimal)
            doc.Call(copy)

            assert_equal(%w[original copy], doc.children.map { it[:id] })
          end

          doc = SVG(:minimal)
          2.times { doc.Call(original) }
          assert_equal(%w[original original], doc.children.map { it[:id] })
        end

        def test_call_rejects_non_module_argument
          assert_raises(ArgumentError) { SVG(:minimal).Call(Object.new) }
        end
      end
    end
  end
end
