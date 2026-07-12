# frozen_string_literal: true

module Sevgi
  class Executor
    # Holds one isolated Sevgi script execution scope and its result.
    #
    # Scope objects belong to one executor run and are pushed onto the current
    # fiber's executor stack. They are not shared between concurrent executions.
    # @api private
    class Scope
      # @!attribute [r] scope
      #   @return [Module] isolated module where script source is evaluated
      # @!attribute [r] recent
      #   @return [Object, nil] last expression result from the executed source
      # @!attribute [r] error
      #   @return [Exception, nil] captured execution error
      attr_reader :scope, :recent, :error

      # Creates a script execution scope.
      # @param scope [Module, nil] existing module to evaluate source in
      # @return [void]
      # @note When no module is supplied, the internal module reports its name as `Sevgi::Main` for readable Ruby error
      #   messages without publishing a process-global `Sevgi::Main` constant.
      def initialize(scope = nil)
        @scope = scope || main
        @recent = nil
        @error = nil
        @stack = {}
        @active = {}
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
        execute(source, receiver, &boot)

        self
      end

      # Captures a preprocessing failure for this scope.
      # @param source [Sevgi::Executor::Source] source active when preprocessing failed
      # @param error [Exception] original preprocessing exception
      # @return [Sevgi::Executor::Scope] self, with error populated
      # @api private
      def capture(source, error)
        push(source)
        @error = error
        self
      end

      # Loads a file into this existing execution scope.
      # @param file [String] source file to read and evaluate
      # @yield optional boot block that installs DSL methods before evaluation
      # @yieldreturn [void]
      # @return [Sevgi::Executor::Scope] self, with recent or error populated
      # @note File-read failures are captured as {Sevgi::Executor::Error} on this scope.
      # @api private
      def load(file, &block)
        call(Source.load(file), &block)
      rescue ::SystemCallError => e
        capture(Source.new(string: "", file:, line: 1), e)
        throw(:result, self)
      end

      # Returns the unique source stack for this execution.
      # @return [Array<String>] source file keys in load order
      # @note The stack is owned by this scope and is not shared with concurrent executions.
      def stack = @stack.keys

      # Builds the immutable public result for this scope.
      # @return [Sevgi::Executor::Result] execution result snapshot
      # @api private
      def result
        sources = stack.freeze
        error = Executor::Error.new(@error, sources) if @error

        Result.new(value: recent, error:, stack: sources)
      end

      # Returns the most recently pushed source.
      # @return [Sevgi::Executor::Source, nil] most recent source object
      # @api private
      def peek = @stack[@stack.keys.last]

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
        Module.new.tap { |mod| mod.define_singleton_method(:name) { "Sevgi::Main" } }
      end

      def push(source)
        tap { @stack[source.key] = source }
      end

      def enter(source)
        if @active.key?(source.identity)
          raise Executor::CycleError, "Recursive Sevgi load: #{source.file}"
        end

        @active[source.identity] = source
        source
      end

      def leave(source)
        return unless source

        @active.delete(source.identity) if @active[source.identity].equal?(source)
      end

      def execute(source, receiver, &boot)
        active = enter(source)
        @recent = run(source, receiver, &boot)
        # rubocop:disable Lint/RescueException
      rescue Exception => e
        @error = e
        throw(:result, self)
        # rubocop:enable Lint/RescueException
      ensure
        leave(active)
      end

      def run(source, receiver, &boot)
        boot(receiver, &boot)
        evaluate(source)
      end
    end
  end
end
