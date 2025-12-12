# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus"

require "sevgi/derender"
require "sevgi/graphics"

include Sevgi::Graphics

unless defined?(TestHelper)
  module TestHelper
    def wtf(...)  = Kernel.puts(...) or Kernel.exit!(0)

    def wtf!(...) = pp(...)          or Kernel.exit!(0)

    def out(actual, file: "/tmp/out", indent: " " * 12)
      File.write(file, actual.gsub(/^/, indent))
      Kernel.exit!(0)
    end
  end

  Minitest::Test.include TestHelper
end

Minitest::Reporters.use!([ Minitest::Reporters::SpecReporter.new ])
