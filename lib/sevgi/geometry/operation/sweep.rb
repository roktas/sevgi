# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      module Sweep
        extend self

        LIMIT = 1_000

        def sweep(element, initial:, direction:, step:, limit: LIMIT, &block)
          line = Equation::Line.from_direction(point: initial, direction:)

          [
            *unisweep(element, line.shift(-step), -step, limit:).reverse,
            *unisweep(element, line, step, limit:)
          ].tap do |segments|
            yield(segments) if block
          end
        end

        def sweep!(element, initial:, direction:, step:, limit: LIMIT, &block)
          sweep(element, initial: initial, direction:, step:, limit:) do |segments|
            OperationError.("No segments found [initial: #{initial}, direction: #{direction} step: #{step}]") if segments.empty?

            yield(segments) if block
          end
        end

        def unisweep(element, line, step, limit: LIMIT)
          segments = []

          limit.times do
            return segments unless (segment = element.intersection(line))

            segments << segment unless segment.ignorable?

            line = line.shift(step)
          end

          OperationError.("Loop limit reached: #{limit}")
        end

        def applicable?(element)
          element.respond_to?(:intersection)
        end
      end

      register(Sweep, :sweep, :sweep!, :unisweep)
    end
  end
end
