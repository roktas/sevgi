# frozen_string_literal: true

require "simplecov" if ENV["COVERAGE"] == "1"

require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus"

require "sevgi/derender"
require "sevgi/graphics"

unless defined?(TestHelper)
  module TestHelper
    def wtf(...)
      Kernel.puts(...) or Kernel.exit!(0)
    end

    def wtf!(...)
      pp(...) or Kernel.exit!(0)
    end

    def out(actual, file: "/tmp/out", indent: " " * 12)
      File.write(file, actual.gsub(/^/, indent))
      Kernel.exit!(0)
    end

    def lines(string) = string.split("\n").map(&:strip).reject(&:empty?)
  end

  Minitest::Test.include(TestHelper)
  Minitest::Test.include(Sevgi::Graphics)
end

Minitest::Reporters.use!([Minitest::Reporters::SpecReporter.new])
