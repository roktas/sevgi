# frozen_string_literal: true

module Sevgi
  module Geometry
    module Operation
      extend self

      OperationError             = Class.new(Error)
      OperationInapplicableError = Class.new(Error)

      def register(handler, *operations) = operations.each { |operation| def_operation(operation, handler) }

      private

        def def_operation(operation, handler)
          define_singleton_method(operation) do |element, *args, **kwargs, &block|
            OperationInapplicableError.("Not a Geometric Element: #{element}")               unless element.is_a?(Element)
            OperationInapplicableError.("Unapplicable operation for #{element}: #{handler}") unless handler.applicable?(element)

            handler.public_send(operation, element, *args, **kwargs, &block)
          end
        end
    end
  end
end

require_relative "operation/align"
require_relative "operation/sweep"
