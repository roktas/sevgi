# frozen_string_literal: true

module Sevgi
  class Executor
    class Scope
      Error = Class.new(::Sevgi::Error)

      attr_reader :scope, :recent, :error

      def initialize(scope = nil)
        @scope = scope || main
        @recent = nil
        @error = nil
        @stack = {}
      end

      def error? = !error.nil?

      def call(source, receiver = nil, &boot)
        push(source)

        tap do
          @recent = begin
            boot(receiver, &boot)
            evaluate(source)
          end

          # rubocop:disable Lint/RescueException
        rescue Exception => e
          @error = Executor::Error.new(e, self)

          throw(:result, self)
          # rubocop:enable Lint/RescueException
        end
      end

      def load(file, &block) = call(Source.load(file), &block)

      def stack = @stack.keys

      def peek = @stack[@stack.keys.last]

      MAIN_MODULE = :Main

      private

      def boot(receiver, &boot)
        return unless boot

        (receiver ||= scope).public_send(receiver.is_a?(::Module) ? :module_exec : :instance_exec, &boot)
      end

      def evaluate(source)
        # Sevgi scripts are executable Ruby DSL source by design.
        scope.module_eval(source.string, source.file, source.line)
      end

      def main
        Module.new.tap do |mod|
          Sevgi.send(:remove_const, MAIN_MODULE) if Sevgi.const_defined?(MAIN_MODULE)
          Sevgi.const_set(MAIN_MODULE, mod)
        end
      end

      def push(source)
        tap { @stack[source.key] = source }
      end
    end
  end
end
