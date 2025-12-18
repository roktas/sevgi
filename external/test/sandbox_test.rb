# frozen_string_literal: true

require_relative "test_helper"

module Sevgi
  class SandboxTest < Minitest::Test
    focus
    def test_load_shutdown
      fixture = "#{__dir__}/fixtures/test_load_shutdown.sevgi"

      assert_raises(PanicError) { Sandbox.load(fixture) }

      Sandbox.instance.create(fixture)
      Sandbox.load(fixture)

      Sandbox.shutdown
      assert_raises(PanicError) { Sandbox.load(fixture) }
    end

    def test_load_error
      fixture = "#{__dir__}/fixtures/test_load_nested.sevgi"

      error = assert_raises(Sandbox::Error) { Sandbox.run(fixture) }

      assert_equal([
        "#{__dir__}/fixtures/test_load_nested.sevgi",
        "#{__dir__}/fixtures/test_load_nested_1.sevgi",
        "#{__dir__}/fixtures/test_load_nested_2.sevgi",
      ], error.stack)

      assert_equal([
        "#{__dir__}/fixtures/test_load_nested_2.sevgi:3:in '<top (required)>'",
        "#{__dir__}/fixtures/test_load_nested_1.sevgi:3:in '<top (required)>'",
        "#{__dir__}/fixtures/test_load_nested.sevgi:5:in '<top (required)>'",
      ].map { it.delete_prefix("#{Dir.pwd}/") }, error.backtrace!)
    end
  end
end
