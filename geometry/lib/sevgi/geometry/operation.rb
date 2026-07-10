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
