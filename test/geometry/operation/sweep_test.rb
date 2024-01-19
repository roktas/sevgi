# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    module Operation
      class SweepTest < Minitest::Test
        include Fixtures

        def test_sweep_diagonal
          initials   = rect345.corners
          directions = [ direction = F.complement(direction345), -direction ]
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
