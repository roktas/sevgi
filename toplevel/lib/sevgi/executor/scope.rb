# frozen_string_literal: true

module Sevgi
  class Executor
    # Holds one isolated Sevgi script execution scope and its result.
    class Scope
      # Error raised by low-level executor scope operations.
      Error = Class.new(::Sevgi::Error)

      # @!attribute [r] scope
      #   @return [Module] isolated module where script source is evaluated
      # @!attribute [r] recent
      #   @return [Object, nil] last expression result from the executed source
      # @!attribute [r] error
      #   @return [Sevgi::Executor::Error, nil] captured execution error
      attr_reader :scope, :recent, :error

      # Creates a script execution scope.
      # @param scope [Module, nil] existing module to evaluate source in
      # @return [void]
      def initialize(scope = nil)
        @scope = scope || main
        @recent = nil
        @error = nil
        @stack = {}
      end

      # Reports whether execution captured an error.
      # @return [Boolean] true when execution failed
      def error? = !error.nil?

      # Executes one source object in this scope.
      # @param source [Sevgi::Executor::Source] source to evaluate
      # @param receiver [Object, nil] receiver used while booting the DSL
      # @yield optional boot block that installs DSL methods before evaluation
      # @yieldreturn [void]
      # @return [Sevgi::Executor::Scope] self, with recent or error populated
      # @api private
      def call(source, receiver = nil, &boot)
        push(source)

        tap do
          @recent = run(source, receiver, &boot)

          # rubocop:disable Lint/RescueException
        rescue Exception => e
          @error = Executor::Error.new(e, self)

          throw(:result, self)
          # rubocop:enable Lint/RescueException
        end
      end

      # Loads a file into this existing execution scope.
      # @param file [String] source file to read and evaluate
      # @yield optional boot block that installs DSL methods before evaluation
      # @yieldreturn [void]
      # @return [Sevgi::Executor::Scope] self, with recent or error populated
      # @raise [Errno::ENOENT] when the file cannot be read
      # @api private
      def load(file, &block) = call(Source.load(file), &block)

      # Returns the unique source stack for this execution.
      # @return [Array<String>] source file keys in load order
      def stack = @stack.keys

      # Returns the most recently pushed source.
      # @return [Sevgi::Executor::Source, nil] most recent source object
      # @api private
      def peek = @stack[@stack.keys.last]

      # Constant name used for the temporary script module under {Sevgi}.
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

      def run(source, receiver, &boot)
        boot(receiver, &boot)
        evaluate(source)
      end
    end
  end
end
