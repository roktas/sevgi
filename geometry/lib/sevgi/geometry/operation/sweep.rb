# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      module Sweep
        extend self

        LIMIT = 1_000

        def sweep(element, initial:, angle:, step:, limit: LIMIT, &block)
          equation = Tuple[Point, initial].equation(angle)

          [
            *unisweep(element, equation.shift(-step), -step, limit:).reverse,
            *unisweep(element, equation, step, limit:)
          ].tap do |lines|
            yield(lines) if block
          end
        end

        def sweep!(element, initial:, angle:, step:, limit: LIMIT, &block)
          sweep(element, initial:, angle:, step:, limit:) do |lines|
            if lines.empty?
              OperationError.("No lines found [initial: #{initial}, angle: #{angle} step: #{step}]")
            end

            yield(lines) if block
          end
        end

        def unisweep(element, equation, step, limit: LIMIT)
          lines = []

          limit.times do
            points = element.intersection(equation)
            return lines if points.empty?

            if points.size == 2 && !(line = Line.(*points)).ignorable?
              lines << line
            end

            equation = equation.shift(step)
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
