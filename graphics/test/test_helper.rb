# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus"

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

module Sevgi::Geometry
  module Fixtures
    #
    # Rect -> o----3----+------- x
    #         | .       |
    #         |  .      |
    #         |   5     4
    #         |     .   |
    #         |      .  |
    #         |       . |
    #         +---------+
    #         |           .
    #         |            . angle = clockwise from x-axis = +53.13°, slope = (4 / 3)
    #         |
    #         y
    #
    def segment345   = @segment345   ||= Segment[Point.origin, Point[3.0, 4.0]]

    def direction345 = @direction345 ||= segment345.direction
    def length345    = @length345    ||= segment345.length
    def rect345      = @rect345      ||= segment345.rect

    #
    #                       . angle = counter clockwise from x-axis = -53.13°, slope = -(4 / 3)
    #                      .
    #                    .
    #         o---------+--------- x
    #         |       . |
    #         |      .  |
    #         |     5   |
    #         |   .     4
    #         |  .      |
    #         |.        |
    # Rect -> +----3----+
    #         |
    #         |
    #         |
    #         y
    #
    def segment543   = @segment543   ||= Segment[Point[0.0, 4.0], Point[3.0, 0.0]]

    def direction543 = @direction543 ||= segment543.direction
    def length543    = @length543    ||= segment543.length
    def rect543      = @rect543      ||= segment543.rect

    def hline4       = @hline4       ||= Equation::Line.horizontal(4.0)
    def vline3       = @vline3       ||= Equation::Line.vertical(3.0)
  end
end
