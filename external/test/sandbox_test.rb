# frozen_string_literal: true

require_relative "test_helper"

module Sevgi
  class SandboxTest < Minitest::Test
    def test_load_shutdown
      fixture = "#{__dir__}/fixtures/simple.sevgi"

      assert_raises(Sandbox::Error) { Sandbox.load!(fixture) }

      Sandbox.load(fixture)
      Sandbox.load(fixture)

      Sandbox.shutdown
      assert_raises(Sandbox::Error) { Sandbox.load!(fixture) }
    end
  end
end
