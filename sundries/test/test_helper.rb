# frozen_string_literal: true

require "simplecov" if ENV["COVERAGE"] == "1"

require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus"

require "sevgi/sundries"

unless defined?(TestHelper)
  module TestHelper
    def assert_geometry_equal(expected, actual)
      if expected.is_a?(::Array) && actual.is_a?(::Array)
        assert_equal(expected.size, actual.size)
        expected.zip(actual).each { |left, right| assert_geometry_equal(left, right) }
      elsif expected.is_a?(Sevgi::Geometry::Element) && actual.is_a?(Sevgi::Geometry::Element)
        assert(expected.eq?(actual), "Expected #{actual.inspect} to approximately equal #{expected.inspect}")
      else
        assert_equal(expected, actual)
      end
    end
  end

  Minitest::Test.include(TestHelper)
end

Minitest::Reporters.use!([Minitest::Reporters::SpecReporter.new])

# rubocop:disable Style/ClassAndModuleChildren
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
    def line345 = @line345 ||= Line.from_points(Origin, [3.0, 4.0])

    def angle345 = @angle345 ||= line345.angle
    def length345 = @length345 ||= line345.length
    def rect345 = @rect345 ||= line345.box

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
    def line543 = @line543 ||= Line.from_points([0.0, 4.0], [3.0, 0.0])

    def angle543 = @angle543 ||= line543.angle
    def length543 = @length543 ||= line543.length
    def rect543 = @rect543 ||= line543.box

    def hequ4 = @hequ4 ||= Equation::Linear.horizontal(4.0)
    def vequ3 = @vequ3 ||= Equation::Linear.vertical(3.0)
  end
end
# rubocop:enable Style/ClassAndModuleChildren
