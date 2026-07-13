# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    module Operation
      class SweepTest < Minitest::Test
        include Fixtures

        def test_sweep_returns_parallel_lines
          rect = Rect[2, 4]

          lines = Operation.sweep(rect, initial: [0, 4], angle: 45, step: ::Math.sqrt(2.0))

          [
            2,
            lines.size,
            [[2.0, 4.0], [0.0, 2.0]],
            lines[0].points.map(&:deconstruct),
            [[0.0, 0.0], [2.0, 2.0]],
            lines[1].points.map(&:deconstruct)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_sweep_returns_empty_outside_element
          rect = Rect[2, 4]

          lines = Operation.sweep(rect, initial: [0, -4], angle: 45, step: 10)

          assert(lines.empty?)
        end

        def test_sweep_signed_step_preserves_covered_lines
          rect = Rect[2, 4]

          positive = Operation.sweep(rect, initial: [0, 2], angle: 0, step: 10)
          negative = Operation.sweep(rect, initial: [0, 2], angle: 0, step: -10)

          assert_equal(line_points(positive), line_points(negative))
        end

        def test_sweep_fails_at_iteration_limit
          rect = Rect[2, 4]
          limit = 5

          lines = Operation.sweep(rect, initial: [0, 4], angle: 45, step: ::Math.sqrt(2.0), limit:)
          assert_equal(2, lines.size)

          assert_raises(OperationError) do
            Operation.sweep(rect, initial: [0, 4], angle: 45, step: ::Math.sqrt(2.0), limit: limit - 1)
          end
        end

        def test_sweep_diagonal_counts_lines_until_limit
          initials = rect345.points
          angles = [angle = 90.0 - angle345, -angle]
          steps = [step = 0.1, -step]
          nsteps = (length345 / step).to_i
          # One terminating iteration per direction.
          limit = nsteps + 2
          expected = nsteps - 1

          sweeper = proc do |limit|
            initials
              .map do |initial|
                angles.map do |angle|
                  steps.map do |step|
                    Operation.sweep!(rect345, initial:, angle:, step:, limit:).size
                  end
                end
              end
              .flatten
          end

          actuals = sweeper.(limit)
          expecteds = Array.new(actuals.size, expected)

          assert_equal(expecteds, actuals)
          assert_raises(OperationError) { sweeper.(limit - 1) }
        end

        def test_sweep_concave_returns_all_spans
          lines = Operation.sweep(concave_u, initial: [0, 2], angle: 0, step: 10)

          assert_equal(
            [
              [[0.0, 2.0], [1.0, 2.0]],
              [[3.0, 2.0], [4.0, 2.0]]
            ],
            line_points(lines)
          )
        end

        def test_sweep_concave_order_independent
          points = concave_u_points
          expected = [
            [[0.0, 2.0], [1.0, 2.0]],
            [[3.0, 2.0], [4.0, 2.0]]
          ]

          [points, points.reverse].each do |path|
            lines = Operation.sweep(Polygon.(*path), initial: [0, 2], angle: 0, step: 10)
            assert_equal(expected, line_points(lines))
          end
        end

        def test_sweep_l_shape_returns_inner_span
          polygon = Polygon.([0, 0], [3, 0], [3, 1], [1, 1], [1, 3], [0, 3])
          lines = Operation.sweep(polygon, initial: [0, 2], angle: 0, step: 10)

          assert_equal([[[0.0, 2.0], [1.0, 2.0]]], line_spans(lines))
        end

        def test_sweep_skips_tangent_vertex
          triangle = Polygon.([0, 0], [2, 2], [4, 0])
          lines = Operation.sweep(triangle, initial: [0, 2], angle: 0, step: 10)

          assert_empty(lines)
        end

        def test_sweep_open_polyline_has_no_interiors
          polyline = Polyline.([0, 0], [2, 2], [4, 0])

          assert_empty(Operation.sweep(polyline, initial: [0, 1], angle: 0, step: 10))
          assert_raises(OperationError) do
            Operation.sweep!(polyline, initial: [2, 1], angle: 0, step: 1)
          end
        end

        def test_sweep_rejects_invalid_progress_arguments
          [
            /step/,
            -> { Operation.sweep(rect345, initial: [0, 0], angle: 0, step: 0) },
            /step/,
            -> { Operation.sweep(rect345, initial: [0, 0], angle: 0, step: Float::NAN) },
            /step/,
            -> { Operation.sweep(rect345, initial: [0, 0], angle: 0, step: Float::INFINITY) },
            /limit/,
            -> { Operation.sweep(rect345, initial: [0, 0], angle: 0, step: 1, limit: 0) },
            /limit/,
            -> { Operation.sweep(rect345, initial: [0, 0], angle: 0, step: 1, limit: -1) },
            /limit/,
            -> { Operation.sweep(rect345, initial: [0, 0], angle: 0, step: 1, limit: 1.0) }
          ].each_slice(2) do |message, operation|
            error = assert_raises(Error, &operation)

            assert_instance_of(Error, error)
            assert_match(message, error.message)
          end
        end

        def test_sweep_self_crossing_open_polyline_has_no_interiors
          polyline = Polyline.([0, 0], [2, 2], [0, 2], [2, 0])

          assert_empty(Operation.sweep(polyline, initial: [0, 1], angle: 0, step: 10))
        end

        def test_sweep_keeps_vertex_crossing_span
          diamond = Polygon.([1, 0], [2, 1], [1, 2], [0, 1])
          lines = Operation.sweep(diamond, initial: [0, 1], angle: 0, step: 10)

          assert_equal([[[0.0, 1.0], [2.0, 1.0]]], line_spans(lines))
        end

        def test_sweep_vertical_returns_parallel_lines
          assert_equal(4, Operation.sweep!(rect345, initial: rect345.position, angle: 90.0, step: 1.0).size)
        end

        def test_sweep_horizontal_returns_parallel_lines
          assert_equal(5, Operation.sweep!(rect345, initial: rect345.position, angle: 0.0, step: 1.0).size)
        end

        private

        def concave_u = Polygon.(*concave_u_points)

        def concave_u_points
          [
            [0, 0],
            [4, 0],
            [4, 4],
            [3, 4],
            [3, 1],
            [1, 1],
            [1, 4],
            [0, 4]
          ]
        end

        def line_spans(lines) = line_points(lines).map(&:sort).sort

        def line_points(lines) = lines.map { it.points.map(&:deconstruct) }
      end
    end
  end
end
