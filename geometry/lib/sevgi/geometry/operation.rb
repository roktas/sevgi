# frozen_string_literal: true

module Sevgi
  module Geometry
    # Stateless operations that relate or derive geometry values.
    #
    # `alignment` returns a translation offset, while `align` applies that
    # offset to a copy. Center alignment works on both axes; edge alignments
    # change only the named axis and preserve the other coordinate. `sweep`
    # derives boundary-to-boundary spans from a closed lined element, and
    # `sweep!` additionally requires at least one span.
    module Operation
      extend self

      # Raised when an operation starts but cannot complete.
      OperationError = Class.new(Error)

      # Raised when an operation does not apply to the target element.
      OperationInapplicableError = Class.new(Error)

      # @!parse
      #   class << self
      #     # Returns an element translated to align with another element.
      #     # Center alignment changes both axes. Edge alignments change only the named axis.
      #     # @param element [Sevgi::Geometry::Element] element to move
      #     # @param other [Sevgi::Geometry::Element] reference element
      #     # @param alignment [Symbol] one of :center, :left, :right, :top, or :bottom
      #     # @return [Sevgi::Geometry::Element] translated element
      #     # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when an argument is not a geometry element
      #     # @raise [Sevgi::ArgumentError] when alignment is unknown
      #     # @example Center one rectangle inside another
      #     #   inner = Sevgi::Geometry::Rect[4, 2]
      #     #   outer = Sevgi::Geometry::Rect[20, 10, position: [5, 5]]
      #     #   Sevgi::Geometry::Operation.align(inner, outer).position.deconstruct # => [13.0, 9.0]
      #     def align(element, other, alignment = :center); end
      #
      #     # Returns the offset needed to align one element with another.
      #     # Center alignment includes both axes. Edge alignments return zero on the other axis.
      #     # @param element [Sevgi::Geometry::Element] element to move
      #     # @param other [Sevgi::Geometry::Element] reference element
      #     # @param alignment [Symbol] one of :center, :left, :right, :top, or :bottom
      #     # @return [Sevgi::Geometry::Point] translation offset
      #     # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when an argument is not a geometry element
      #     # @raise [Sevgi::ArgumentError] when alignment is unknown
      #     # @example Calculate an offset without moving the element
      #     #   inner = Sevgi::Geometry::Rect[4, 2]
      #     #   outer = Sevgi::Geometry::Rect[20, 10, position: [5, 5]]
      #     #   Sevgi::Geometry::Operation.alignment(inner, outer, :bottom).approx.deconstruct # => [0.0, 13.0]
      #     def alignment(element, other, alignment = :center); end
      #
      #     # Sweeps parallel lines across a lined element in both directions.
      #     # `angle` is the direction of the returned lines; `step` is their signed perpendicular spacing.
      #     # Open paths yield no interior spans.
      #     # @param element [Sevgi::Geometry::Element::Lined] element to intersect
      #     # @param initial [Sevgi::Geometry::Point, Array<Numeric>] point on the initial sweep line
      #     # @param angle [Numeric] clockwise sweep line angle in degrees
      #     # @param step [Numeric] signed distance between sweep lines
      #     # @param limit [Integer] maximum iterations per direction
      #     # @yield [lines] optional hook receiving the generated lines
      #     # @yieldparam lines [Array<Sevgi::Geometry::Line>] generated sweep lines
      #     # @yieldreturn [void]
      #     # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
      #     # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when element is not sweepable
      #     # @raise [Sevgi::Geometry::Error] when initial, angle, step, or limit is invalid
      #     # @raise [Sevgi::Geometry::Operation::OperationError] when iteration reaches the limit
      #     # @example Generate horizontal spans through a rectangle
      #     #   rect = Sevgi::Geometry::Rect[10, 6]
      #     #   lines = Sevgi::Geometry::Operation.sweep(rect, initial: [0, 0], angle: 0, step: 2)
      #     #   lines.size                # => 4
      #     #   lines.map(&:length).uniq # => [10.0]
      #     def sweep(element, initial:, angle:, step:, limit: Sweep::LIMIT); end
      #
      #     # Sweeps parallel lines across a lined element and requires at least one result.
      #     # It has the same geometry as {sweep}, but raises when the result would be empty.
      #     # @param element [Sevgi::Geometry::Element::Lined] element to intersect
      #     # @param initial [Sevgi::Geometry::Point, Array<Numeric>] point on the initial sweep line
      #     # @param angle [Numeric] clockwise sweep line angle in degrees
      #     # @param step [Numeric] signed distance between sweep lines
      #     # @param limit [Integer] maximum iterations per direction
      #     # @yield [lines] optional hook receiving the generated lines
      #     # @yieldparam lines [Array<Sevgi::Geometry::Line>] generated sweep lines
      #     # @yieldreturn [void]
      #     # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
      #     # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when element is not sweepable
      #     # @raise [Sevgi::Geometry::Error] when initial, angle, step, or limit is invalid
      #     # @raise [Sevgi::Geometry::Operation::OperationError] when no lines are found or iteration reaches the limit
      #     def sweep!(element, initial:, angle:, step:, limit: Sweep::LIMIT); end
      #   end
      # Registers one or more public operation methods.
      # @api private
      # @param handler [Module] operation handler module
      # @param operations [Array<Symbol>] operation method names
      # @return [Array<Symbol>] registered operation names
      def register(handler, *operations) = operations.each { |operation| def_operation(operation, handler) }

      private :register

      private

      def def_operation(operation, handler)
        define_singleton_method(operation) do |element, *args, **kwargs, &block|
          OperationInapplicableError.("Not a Geometric Element: #{element}") unless element.is_a?(Element)
          unless handler.applicable?(element)
            OperationInapplicableError.("Operation not applicable to #{element}: #{handler}")
          end

          handler.public_send(operation, element, *args, **kwargs, &block)
        end
      end
    end
  end
end

require_relative "operation/align"
require_relative "operation/sweep"
