# frozen_string_literal: true

require "open3"
require "rbconfig"

require_relative "test_helper"

module Sevgi
  class CoreTest < Minitest::Test
    def test_error_call_raises_subclass
      error = assert_raises(PanicError) { PanicError.("boom") }

      assert_equal("boom", error.message)
    end

    def test_error_classes_inherit_error
      [
        ArgumentError,
        MissingComponentError,
        PanicError
      ].each { assert_operator(it, :<, Error) }
    end

    def test_missing_component_error_reports_required_component
      error = assert_raises(MissingComponentError) { MissingComponentError.("sevgi/geometry") }

      assert_equal("sevgi/geometry", error.component)
      assert_equal("\"sevgi/geometry\" required", error.message)
      assert_kind_of(Error, error)
    end

    def test_undefined_coalesce_preserves_nil
      assert_nil(Undefined.coalesce(Undefined, nil, :value))
      assert_equal(:value, Undefined.coalesce(Undefined, Undefined, :value))
    end

    def test_undefined_coalesce_returns_nil_for_all_undefined
      assert_nil(Undefined.coalesce(Undefined, Undefined))
    end

    def test_undefined_default_uses_fallback
      assert_equal(:value, Undefined.default(:value, :fallback))
      assert_equal(:fallback, Undefined.default(Undefined, :fallback))
      assert_equal(:computed, Undefined.default(Undefined) { :computed })
    end

    def test_undefined_map_skips_sentinel
      assert_same(Undefined, Undefined.map(Undefined) { :mapped })
      assert_equal(:mapped, Undefined.map(:value) { :mapped })
    end

    def test_undefined_clone_accepts_freeze_keyword
      assert_same(Undefined, Undefined.clone)
      assert_same(Undefined, Undefined.clone(freeze: true))
      assert_same(Undefined, Undefined.clone(freeze: false))
    end

    def test_sevgi_constants_ignore_top_level_collisions
      lib = ::File.expand_path("../../lib", __dir__)
      script = <<~RUBY
        ::Error = Class.new(StandardError)
        ::F = :external
        require "sevgi/function"
        print [Sevgi.const_defined?(:Error, false), Sevgi.const_defined?(:F, false)].join(",")
      RUBY
      out, err, status = ::Open3.capture3(::RbConfig.ruby, "-I#{lib}", "-e", script)

      assert_predicate(status, :success?, err)
      assert_equal("true,true", out)
    end
  end
end
