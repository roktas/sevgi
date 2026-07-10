# frozen_string_literal: true

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

    def test_undefined_coalesce_returns_nil_when_all_values_are_undefined
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
  end
end
