# frozen_string_literal: true

module Sevgi
  module Geometry
    # Dispatches geometry operations to operation handler modules.
    module Operation
      extend self

      # Raised when an operation starts but cannot complete.
      OperationError = Class.new(Error)

      # Raised when an operation does not apply to the target element.
      OperationInapplicableError = Class.new(Error)

      # @!parse
      #   class << self
      #     # Returns an element translated to align with another element.
      #     # @param element [Sevgi::Geometry::Element] element to move
      #     # @param other [Sevgi::Geometry::Element] reference element
      #     # @param alignment [Symbol] one of :center, :left, :right, :top, or :bottom
      #     # @return [Sevgi::Geometry::Element] translated element
      #     # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when an argument is not a geometry element
      #     # @raise [Sevgi::ArgumentError] when alignment is unknown
      #     def align(element, other, alignment = :center); end
      #
      #     # Returns the offset needed to align one element with another.
      #     # @param element [Sevgi::Geometry::Element] element to move
      #     # @param other [Sevgi::Geometry::Element] reference element
      #     # @param alignment [Symbol] one of :center, :left, :right, :top, or :bottom
      #     # @return [Sevgi::Geometry::Point] translation offset
      #     # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when an argument is not a geometry element
      #     # @raise [Sevgi::ArgumentError] when alignment is unknown
      #     def alignment(element, other, alignment = :center); end
      #
      #     # Sweeps parallel lines across a lined element in both directions.
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
      #     # @raise [Sevgi::Geometry::Error] when initial, step, or limit is invalid
      #     # @raise [Sevgi::Geometry::Operation::OperationError] when iteration reaches the limit
      #     def sweep(element, initial:, angle:, step:, limit: Sweep::LIMIT); end
      #
      #     # Sweeps parallel lines across a lined element and requires at least one result.
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
      #     # @raise [Sevgi::Geometry::Error] when initial, step, or limit is invalid
      #     # @raise [Sevgi::Geometry::Operation::OperationError] when no lines are found or iteration reaches the limit
      #     def sweep!(element, initial:, angle:, step:, limit: Sweep::LIMIT); end
      #
      #     # Sweeps parallel lines in one signed direction from an equation.
      #     # @param element [Sevgi::Geometry::Element::Lined] element to intersect
      #     # @param equation [Sevgi::Geometry::Equation] initial sweep equation
      #     # @param step [Numeric] signed distance between sweep lines
      #     # @param limit [Integer] maximum iterations
      #     # @return [Array<Sevgi::Geometry::Line>] generated sweep lines
      #     # @raise [Sevgi::Geometry::Operation::OperationInapplicableError] when element is not sweepable
      #     # @raise [Sevgi::Geometry::Error] when step or limit is invalid
      #     # @raise [Sevgi::Geometry::Operation::OperationError] when iteration reaches the limit
      #     def unisweep(element, equation, step, limit: Sweep::LIMIT); end
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
            OperationInapplicableError.("Unapplicable operation for #{element}: #{handler}")
          end

          handler.public_send(operation, element, *args, **kwargs, &block)
        end
      end
    end
  end
end

require_relative "operation/align"
require_relative "operation/sweep"
