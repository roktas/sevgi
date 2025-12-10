# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class InternalListTest < Minitest::Test
    def test_list_import_basics
      mod = Module.new.extend(List)

      mod.import(x: 19, y: 42)

      assert_equal([ 19, 42 ], [ mod[:x], mod[:y] ])
    end

    def test_list_import_merging
      mod = Module.new.extend(List)

      mod.import(x: 19, y: 42)
      mod.import(y: 13, z: 100)

      assert_equal([ 19, 42, 100 ], [ mod[:x], mod[:y], mod[:z] ])
    end

    def test_valid_method
      mod = Module.new.extend(List)

      mod.import(x: 19, y: 42)

      assert(mod.valid?(:x))
      refute(mod.valid?(:z))
    end
  end
end
