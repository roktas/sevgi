# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      # Sweep operation implementation.
      # @api private
      module Sweep
        extend self

        # Default maximum number of sweep iterations.
        LIMIT = 1_000

        # Sweeps parallel lines across a lined element in both directions.
        #
        # Generated lines are boundary-to-boundary interior spans. A single
        # sweep position can produce multiple lines for closed concave elements; open paths produce no interior lines.
        # @param element [Sevgi::Geometry::Element::Lined] element to intersect
        # @param initial [Sevgi::Geometry::Point, Array<Numeric>] point on the initial sweep line
        # @param angle [Numeric] clockwise sweep line angle in degrees
        # @param step [Numeric] signed distance between sweep lines
        # @param limit [Integer] maximum iterations per direction
        # @yield [lines] optional hook receiving the generated lines
        # @yieldparam lines [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @yieldreturn [void]
        # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @raise [Sevgi::Geometry::Error] when initial, angle, step, or limit is invalid
        # @raise [Sevgi::Geometry::Operation::OperationError] when iteration reaches the limit
        def sweep(element, initial:, angle:, step:, limit: LIMIT, &block)
          step = validate_arguments(step, limit)
          equation = Tuple[Point, initial].equation(angle)

          [
            *unisweep(element, equation.shift(-step), -step, limit:).reverse,
            *unisweep(element, equation, step, limit:)
          ].tap do |lines|
            yield(lines) if block
          end
        end

        # Sweeps parallel lines across a lined element and requires at least one result.
        #
        # Generated lines are boundary-to-boundary interior spans. A single
        # sweep position can produce multiple lines for closed concave elements; open paths produce no interior lines.
        # @param element [Sevgi::Geometry::Element::Lined] element to intersect
        # @param initial [Sevgi::Geometry::Point, Array<Numeric>] point on the initial sweep line
        # @param angle [Numeric] clockwise sweep line angle in degrees
        # @param step [Numeric] signed distance between sweep lines
        # @param limit [Integer] maximum iterations per direction
        # @yield [lines] optional hook receiving the generated lines
        # @yieldparam lines [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @yieldreturn [void]
        # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @raise [Sevgi::Geometry::Error] when initial, angle, step, or limit is invalid
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
        #
        # Generated lines are boundary-to-boundary interior spans. A single
        # sweep position can produce multiple lines for closed concave elements; open paths produce no interior lines.
        # @param element [Sevgi::Geometry::Element::Lined] element to intersect
        # @param equation [Sevgi::Geometry::Equation] initial sweep equation
        # @param step [Numeric] signed distance between sweep lines
        # @param limit [Integer] maximum iterations
        # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
        # @raise [Sevgi::Geometry::Error] when step or limit is invalid
        # @raise [Sevgi::Geometry::Operation::OperationError] when iteration reaches the limit
        def unisweep(element, equation, step, limit: LIMIT)
          step = validate_arguments(step, limit)
          lines = []

          limit.times do
            points = element.intersection(equation)
            return lines if points.empty?

            lines.concat(interior_lines(element, equation, points))

            equation = equation.shift(step)
          end

          OperationError.("Loop limit reached: #{limit}")
        end

        private :unisweep

        # Reports whether the sweep handler can operate on an element.
        # @api private
        # @param element [Object] candidate element
        # @return [Boolean]
        def applicable?(element)
          element.respond_to?(:intersection)
        end

        private

        def validate_arguments(step, limit)
          step = Real[:step, step]
          Error.("Sweep step must be nonzero") if step.zero?
          unless limit.is_a?(::Integer) && limit.positive?
            Error.("Sweep limit must be a positive Integer: #{limit.inspect}")
          end

          step
        end

        def interior_lines(element, equation, points)
          return [] unless element.class.send(:close?)

          if points.size == 2
            line = simple_line(points)

            return line ? [line] : []
          end

          sorted_points(equation, points).each_cons(2).filter_map do |starting, ending|
            next unless element.inside?(midpoint(starting, ending))

            simple_line([starting, ending])
          end
        end

        def midpoint(starting, ending)
          Point[(starting.x + ending.x) / 2.0, (starting.y + ending.y) / 2.0]
        end

        def simple_line(points)
          line = Line.(*points)

          line unless line.ignorable?
        end

        def sorted_points(equation, points)
          points.sort_by do |point|
            equation.is_a?(Equation::Linear::Vertical) ? [point.y, point.x] : [point.x, point.y]
          end
        end
      end

      register(Sweep, :sweep, :sweep!)

      private_constant :Sweep
    end
  end
end
