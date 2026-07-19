# frozen_string_literal: true

require "simplecov" if ENV["COVERAGE"] == "1"

require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"

require "sevgi-appendix"

Minitest::Reporters.use!([Minitest::Reporters::SpecReporter.new])
