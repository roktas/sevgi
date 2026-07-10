# frozen_string_literal: true

require "simplecov" if ENV["COVERAGE"] == "1"

require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus"

require "sevgi/function"

Minitest::Reporters.use!([Minitest::Reporters::SpecReporter.new])
