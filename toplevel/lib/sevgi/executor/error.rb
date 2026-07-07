# frozen_string_literal: true

module Sevgi
  class Executor
    # Wraps an exception raised while executing Sevgi script source.
    class Error < ::Sevgi::Error
      # @!attribute [r] error
      #   @return [Exception] original exception raised by script execution
      # @!attribute [r] scope
      #   @return [Sevgi::Executor::Scope] executor scope active when the error was captured
      attr_reader :error, :scope

      # Builds an executor error wrapper.
      # @param error [Exception] original exception
      # @param scope [Sevgi::Executor::Scope] executor scope active at failure time
      # @return [void]
      def initialize(error, scope)
        @error = error
        @scope = scope

        super(error.message)
      end

      # Returns backtrace entries that belong to the Sevgi load stack.
      # @return [Array<String>] filtered backtrace lines relative to the current directory
      def backtrace!
        sources = stack.map { ::File.expand_path(it) }

        error
          .backtrace
          .select { sources.include?(::File.expand_path(it.split(":", 2).first)) }
          .map { |line| line.delete_prefix("#{::Dir.pwd}/") }
      end

      # Returns the script load stack active at failure time.
      # @return [Array<String>] script file names in load order
      def stack = scope.stack
    end
  end
end
