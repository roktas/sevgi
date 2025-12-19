# frozen_string_literal: true

require_relative "test_helper"

require "sevgi/binaries/sevgi"

module Sevgi
  module Binaries
    class SevgiTest < Minitest::Test
      def test_load_nested
        fixture = "#{__dir__}/fixtures/test_load_nested.sevgi"

        Sevgi.(fixture)
      end
    end
  end
end
