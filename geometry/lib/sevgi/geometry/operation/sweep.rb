# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      # Sweep operation implementation.
      module Sweep
        extend self

        # Default maximum number of sweep iterations.
        LIMIT = 1_000

        # Sweeps parallel lines across an element in both directions.
        # @param element [Sevgi::Geometry::Element] element to intersect
        # @param initial [Sevgi::Geometry::Point, Array<Numeric>] point on the initial sweep line
        # @param angle [Numeric] clockwise sweep line angle in degrees
        # @param step [Numeric] signed distance between sweep lines
        # @param limit [Integer] maximum iterations per direction
        # @yield [lines] optional hook receiving the generated lines
        # @yieldparam lines [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @yieldreturn [void]
        # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @raise [Sevgi::Geometry::Error] when initial cannot be coerced
        # @raise [Sevgi::Geometry::Operation::OperationError] when iteration reaches the limit
        def sweep(element, initial:, angle:, step:, limit: LIMIT, &block)
          equation = Tuple[Point, initial].equation(angle)

          [
            *unisweep(element, equation.shift(-step), -step, limit:).reverse,
            *unisweep(element, equation, step, limit:)
          ].tap do |lines|
            yield(lines) if block
          end
        end

        # Sweeps parallel lines and requires at least one result.
        # @param element [Sevgi::Geometry::Element] element to intersect
        # @param initial [Sevgi::Geometry::Point, Array<Numeric>] point on the initial sweep line
        # @param angle [Numeric] clockwise sweep line angle in degrees
        # @param step [Numeric] signed distance between sweep lines
        # @param limit [Integer] maximum iterations per direction
        # @yield [lines] optional hook receiving the generated lines
        # @yieldparam lines [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @yieldreturn [void]
        # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @raise [Sevgi::Geometry::Error] when initial cannot be coerced
        # @raise [Sevgi::Geometry::Operation::OperationError] when no lines are found or iteration reaches the limit
        def sweep!(element, initial:, angle:, step:, limit: LIMIT, &block)
          sweep(element, initial:, angle:, step:, limit:) do |lines|
            if lines.empty?
              OperationError.("No lines found [initial: #{initial}, angle: #{angle} step: #{step}]")
            end

            yield(lines) if block
          end
        end

        # Sweeps parallel lines in one signed direction from an equation.
        # @param element [Sevgi::Geometry::Element] element to intersect
        # @param equation [Sevgi::Geometry::Equation] initial sweep equation
        # @param step [Numeric] signed distance between sweep lines
        # @param limit [Integer] maximum iterations
        # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @raise [Sevgi::Geometry::Operation::OperationError] when iteration reaches the limit
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

        # Reports whether the sweep handler can operate on an element.
        # @api private
        # @param element [Object] candidate element
        # @return [Boolean]
        def applicable?(element)
          element.respond_to?(:intersection)
        end
      end

      register(Sweep, :sweep, :sweep!, :unisweep)
    end
  end
end
