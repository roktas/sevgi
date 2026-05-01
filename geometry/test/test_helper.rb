# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus"

require "sevgi/geometry"

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
    def line345   = @line345   ||= Line.(Origin, [ 3.0, 4.0 ])

    def angle345  = @angle345  ||= line345.angle
    def length345 = @length345 ||= line345.length
    def rect345   = @rect345   ||= line345.box

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
    def line543   = @line543   ||= Line.([ 0.0, 4.0 ], [ 3.0, 0.0 ])

    def angle543  = @angle543  ||= line543.angle
    def length543 = @length543 ||= line543.length
    def rect543   = @rect543   ||= line543.box

    def hequ4     = @hequ4     ||= Equation::Linear.horizontal(4.0)
    def vequ3     = @vequ3     ||= Equation::Linear.vertical(3.0)
  end
end
