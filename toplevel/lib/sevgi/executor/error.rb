# frozen_string_literal: true

module Sevgi
  class Executor
    # Raised when a source attempts to load another source already active in the same scope.
    class CycleError < ::Sevgi::Error
    end

    # Wraps an exception raised while executing Sevgi script source.
    class Error < ::Sevgi::Error
      # Builds an executor error wrapper.
      # @param error [Exception] original exception
      # @param stack [Array<String>] visited source file keys; the Array and its String entries are copied and frozen
      # @return [void]
      def initialize(error, stack)
        @cause = error
        @stack = stack.map { it.dup.freeze }.freeze

        super(error.message)
      end

      # Returns backtrace entries that belong to the captured Sevgi load stack.
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
