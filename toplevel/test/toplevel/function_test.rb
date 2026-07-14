# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelFunctionTest < Minitest::Test
    PROMOTED_CONSTANTS = %i[Export F Geometry Origin].freeze

    def test_include_promotes_canonical_function_alias
      receiver = Class.new do
        include(Sevgi)
      end

      assert_same(Sevgi::F, receiver.const_get(:F, false))
      assert_respond_to(receiver.const_get(:F, false), :existing!)
    end

    def test_extend_module_promotes_canonical_function_alias
      receiver = ::Module.new

      receiver.extend(Sevgi)

      assert_same(Sevgi::F, receiver.const_get(:F, false))
      assert_respond_to(receiver.const_get(:F, false), :existing!)
    end

    def test_extend_object_doesnt_mutate_object_constants
      before = object_promoted_constants

      Object.new.extend(Sevgi)

      assert_equal(before, object_promoted_constants)
    end

    private

    def object_promoted_constants
      PROMOTED_CONSTANTS.to_h { |name| [name, Object.const_defined?(name, false)] }
    end
  end
end
