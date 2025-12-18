# frozen_string_literal: true

require_relative "test_helper"

require "sevgi/runtimes/cli"

module Sevgi
  class ExternalTest < Minitest::Test
    def test_load_nested
      fixture = "#{__dir__}/fixtures/test_load_nested.sevgi"

      CLI.(fixture)
    end
  end
end
