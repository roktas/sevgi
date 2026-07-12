# frozen_string_literal: true

module Sevgi
  class Executor
    # Describes the outcome of one executor invocation.
    #
    # A successful result has a value and no error. A captured script, file, or
    # library failure has an {Executor::Error} and may retain a value produced
    # before the failure. The source stack is an immutable snapshot in load
    # order; it is never shared with the executor's internal mutable state.
    #
    # @example Inspect successful execution
    #   result = Sevgi::Executor.execute("6 * 7")
    #   result.success? #=> true
    #   result.value    #=> 42
    #
    # @example Inspect a captured failure
    #   result = Sevgi::Executor.execute("missing", file: "drawing.sevgi")
    #   result.error?       #=> true
    #   result.error.cause  #=> #<NameError ...>
    #   result.stack        #=> ["drawing.sevgi"]
    #
    # @see Executor.execute
    # @see Executor.execute_file
    Result = Data.define(:value, :error, :stack) do
      # @!attribute [r] value
      #   @return [Object, nil] last value produced, or nil when no value was produced
      # @!attribute [r] error
      #   @return [Sevgi::Executor::Error, nil] captured failure, or nil after successful execution
      # @!attribute [r] stack
      #   @return [Array<String>] frozen owned source-path snapshot in load order

      # Creates an execution result.
      # @param value [Object, nil] last value produced before execution finished
      # @param error [Sevgi::Executor::Error, nil] captured execution failure
      # @param stack [Array<String>] source files visited in load order
      # @return [void]
      def initialize(value:, error:, stack:)
        super(value:, error:, stack: Array(stack).map { it.dup.freeze }.freeze)
      end

      private_class_method :[]

      # Reports whether execution completed without a captured error.
      # @return [Boolean] true when execution succeeded
      def success? = error.nil?

      # Reports whether execution captured an error.
      # @return [Boolean] true when execution failed
      def error? = !success?
    end
  end
end
