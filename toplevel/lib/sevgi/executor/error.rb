# frozen_string_literal: true

module Sevgi
  class Executor
    # Raised when a source attempts to load another source already active in the same scope.
    # @see https://sevgi.roktas.dev/usage/#execute Execute source guide
    class CycleError < ::Sevgi::Error
    end

    # Raised when nested Sevgi loads exceed the executor's supported active-source depth.
    #
    # Excessive acyclic nesting usually indicates an indirect recursive load pattern that
    # escaped ordinary cycle detection through generated or otherwise distinct source files.
    # @see https://sevgi.roktas.dev/usage/#execute Execute source guide
    class LoadDepthError < ::Sevgi::Error
    end

    # Wraps an exception raised while executing Sevgi script source. Its visited source snapshot records every source in
    # load order. It is not the active load stack at the instant of failure.
    # @see https://sevgi.roktas.dev/usage/#execute Execute source guide
    class Error < ::Sevgi::Error
      # Builds an executor error wrapper.
      # @param error [Exception] original exception
      # @param stack [Array<String>] source file keys visited in load order. The Array and its String entries are copied
      #   and frozen
      # @return [void]
      def initialize(error, stack)
        @cause = error
        @stack = stack.map { it.dup.freeze }.freeze

        super(error.message)
      end

      # Returns backtrace entries that belong to the visited Sevgi source set.
      # @return [Array<String>] filtered backtrace lines relative to the current directory, or an empty Array when the
      #   original exception has no backtrace
      def load_backtrace
        sources = @stack.map { ::File.expand_path(it) }

        Array(cause.backtrace)
          .select { sources.include?(::File.expand_path(it.split(":", 2).first)) }
          .map { |line| line.delete_prefix("#{::Dir.pwd}/") }
      end

      # Returns the original exception as the wrapped cause.
      # @return [Exception]
      attr_reader :cause
    end
  end
end
