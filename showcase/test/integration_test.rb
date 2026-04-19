# frozen_string_literal: true

require_relative "test_helper"

require "sevgi/showcase"

module Sevgi
  EXAMPLES = Test::Suite.new(File.expand_path("#{__dir__}/../srv"))

  class IntegrationTest < Minitest::Test
    def test_all_valid_outputs_are_identical
      EXAMPLES.valids.each do |script|
        result = script.run_passive

        assert_empty(result.err)
        assert_equal(::File.read(script.svg).chomp, result.to_s)
      end
    end
  end
end
