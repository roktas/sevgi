# frozen_string_literal: true

require_relative "test_helper"

module Sevgi
  class CoreTest < Minitest::Test
    def test_error_call_raises_subclass
      error = assert_raises(PanicError) { PanicError.("boom") }

      assert_equal("boom", error.message)
    end

    def test_undefined_coalesce_preserves_nil
      assert_nil(Undefined.coalesce(Undefined, nil, :value))
      assert_equal(:value, Undefined.coalesce(Undefined, Undefined, :value))
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
