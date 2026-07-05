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
        sources = stack.map { ::File.expand_path(it) }

        error
          .backtrace
          .select { sources.include?(::File.expand_path(it.split(":", 2).first)) }
          .map { |line| line.delete_prefix("#{::Dir.pwd}/") }
      end

      def stack = scope.stack
    end
  end
end
