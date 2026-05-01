# frozen_string_literal: true

module Sevgi
  class Executor
    class Error < ::Sevgi::Error
      attr_reader :error, :scope

      def initialize(error, scope)
        @error = error
        @scope = scope

        super(error.message)
      end

      def backtrace!
        error.backtrace
          .select { |line| stack.any? { line.start_with?(::File.expand_path(it)) } }
          .map    { |line| line.delete_prefix("#{::Dir.pwd}/") }
      end

      def stack = scope.stack
    end
  end
end
