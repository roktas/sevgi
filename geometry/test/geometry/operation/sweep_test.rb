# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    module Operation
      class SweepTest < Minitest::Test
        include Fixtures

        def test_sweep_unisweep_success
          rect = Rect[2, 4]
          equ  = Equation.diagonal(slope: 1.0, intercept: 4.0)

          lines = Operation.unisweep(rect, equ, ::Math.sqrt(2.0))

          [
            2,                                   lines.size,
            [ [ 2.0, 4.0 ], [ 0.0, 2.0 ] ],      lines[0].points.map(&:deconstruct),
            [ [ 0.0, 0.0 ], [ 2.0, 2.0 ] ],      lines[1].points.map(&:deconstruct),
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_sweep_unisweep_failure_because_of_intercept
          rect = Rect[2, 4]
          equ  = Equation.diagonal(slope: 1.0, intercept: -4.0)

          lines = Operation.unisweep(rect, equ, ::Math.sqrt(2.0))

          assert(lines.empty?)
        end

        def test_sweep_unisweep_failure_because_of_step
          rect = Rect[2, 4]
          equ  = Equation.diagonal(slope: 1.0, intercept: 4.0)

          lines = Operation.unisweep(rect, equ, -::Math.sqrt(2.0))

          assert(lines.empty?)
        end

        def test_sweep_unisweep_failure_because_of_limit
          rect = Rect[2, 4]
          equ  = Equation.diagonal(slope: 1.0, intercept: 4.0)

          limit = 5

          lines = Operation.unisweep(rect, equ, ::Math.sqrt(2.0), limit:)
          assert_equal(2, lines.size)

          assert_raises(OperationError) do
            Operation.unisweep(rect, equ, ::Math.sqrt(2.0), limit: limit - 1)
          end
        end

        def test_sweep_diagonal
          initials   = rect345.points
          directions = [ direction = 90.0 - angle345, -direction ]
          steps      = [ step = 0.1, -step ]
          nsteps     = (length345 / step).to_i
          limit      = nsteps + 2 # +1 for each unisweep, +2 in total
          expected   = nsteps - 1

          sweeper    = proc do |limit|
            initials.map do |initial|
              directions.map do |direction|
                steps.map do |step|
                  Operation.sweep!(rect345, initial:, direction:, step:, limit:).size
                end
              end
            end.flatten
          end

          actuals   = sweeper.(limit)
          expecteds = Array.new(actuals.size, expected)

          assert_equal(expecteds, actuals)
          assert_raises(OperationError) { sweeper.(limit - 1) }
        end

        def test_sweep_vertical
          assert_equal(4, Operation.sweep!(rect345, initial: rect345.position, direction: 90.0, step: 1.0).size)
        end

        def test_sweep_horizontal
          assert_equal(5, Operation.sweep!(rect345, initial: rect345.position, direction: 0.0, step: 1.0).size)
        end
      end
    end
  end
end
