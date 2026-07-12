# frozen_string_literal: true

require "sevgi/function"

require_relative "executor/error"
require_relative "executor/result"
require_relative "executor/scope"
require_relative "executor/source"

module Sevgi
  # Executes Sevgi script source inside an isolated module scope.
  #
  # The executor is used by script mode and by the `Load` DSL word to preserve a
  # useful load stack while keeping DSL methods out of the caller's global object
  # whenever possible. Active scope stacks are isolated per Ruby fiber, so
  # concurrent executions can perform nested `Load` calls without sharing scope
  # state. The process SIGINT handler is shared by Ruby, so executor runs guard it
  # with a reference-counted critical section and restore the previous handler
  # after the last active execution finishes.
  #
  # @example Execute source and inspect its result
  #   result = Sevgi::Executor.execute("6 * 7")
  #   result.success? #=> true
  #   result.value    #=> 42
  class Executor
    private_class_method :new
    private_constant :Scope

    # Thread-current key used for the fiber-local executor scope stack.
    # @api private
    SCOPE_KEY = :sevgi_executor_scopes
    SOURCE_LINE_MAX = (2 ** 31) - 1
    private_constant :SCOPE_KEY, :SOURCE_LINE_MAX, :Source

    # Owns mutable execution and process-signal state outside the public executor surface.
    # @api private
    class State
      def initialize
        @signal_count = 0
        @signal_mutex = Mutex.new
        @signal_previous = nil
      end

      def create(scope = nil) = Scope.new(scope).tap { scopes << it }
      def current = scopes.last

      def restore
        @signal_mutex.synchronize do
          next if @signal_count.zero?

          @signal_count -= 1
          next unless @signal_count.zero?

          Signal.trap("INT", @signal_previous)
          @signal_previous = nil
        end
      end

      def shutdown(scope = nil)
        return scopes.pop unless scope
        return scopes.pop if scopes.last.equal?(scope)

        scopes.delete(scope)
      end

      def trap
        @signal_mutex.synchronize do
          @signal_previous = Signal.trap("INT") { Kernel.abort("") } if @signal_count.zero?
          @signal_count += 1
        end
      end

      private

      def scopes = Thread.current[SCOPE_KEY] ||= []
    end

    STATE = State.new
    private_constant :STATE, :State

    # Loads a script file inside the current executor scope.
    # @param file [String] path to a Sevgi script file
    # @return [Sevgi::Executor::Scope] current internal execution scope
    # @raise [Sevgi::PanicError] when there is no active executor scope
    # @note Uses the active executor scope from the current fiber.
    # @api private
    def self.load(file, ...)
      PanicError.("box stack empty; create a box first") unless STATE.current

      STATE.current.load(file, ...)
    end

    # Executes Ruby source inside a managed Sevgi script scope.
    # @param string [String] source to evaluate
    # @param file [String, nil] source file name used for errors and backtraces
    # @param line [Integer, nil] starting source line used for errors and backtraces
    # @param require [String, nil] optional Ruby library to require before execution
    # @param receiver [Object, nil] receiver used verbatim while booting the DSL; nil selects the isolated execution
    #   module, while false and other executable objects remain explicit receivers
    # @yield optional boot block that installs DSL methods before evaluation
    # @yieldreturn [void]
    # @return [Sevgi::Executor::Result] immutable execution result
    # @raise [Sevgi::ArgumentError] when source, file, line, required library, or receiver is invalid
    # @note Script and required-library failures are captured in {Sevgi::Executor::Result#error}; inspect
    #   {Sevgi::Executor::Error#cause} for the original exception.
    # @note Reentrant and concurrent calls keep independent scope stacks per fiber. The temporary SIGINT handler remains
    #   process-global while any execution is active.
    def self.execute(string, file: nil, line: nil, require: nil, receiver: nil, &block)
      validate_source!(string, file, line)
      validate_context!(require, receiver)

      execute_source(Source.new(string:, file:, line:), require:, receiver:, &block)
    end

    # Executes a file inside a managed Sevgi script scope.
    # @param file [String] source file to read and execute
    # @param require [String, nil] optional Ruby library to require before execution
    # @param receiver [Object, nil] receiver used verbatim while booting the DSL; nil selects the isolated execution
    #   module, while false and other executable objects remain explicit receivers
    # @yield optional boot block that installs DSL methods before evaluation
    # @yieldreturn [void]
    # @return [Sevgi::Executor::Result] immutable execution result
    # @raise [Sevgi::ArgumentError] when file, required library, or receiver is invalid
    # @note File-read, script, and required-library failures are captured in {Sevgi::Executor::Result#error}; inspect
    #   {Sevgi::Executor::Result#stack} for nested loads.
    # @note Reentrant and concurrent calls keep independent scope stacks per fiber. The temporary SIGINT handler remains
    #   process-global while any execution is active.
    def self.execute_file(file, require: nil, receiver: nil, &block)
      ArgumentError.("Executor file must be a String") unless file.is_a?(::String)
      validate_context!(require, receiver)

      source = nil
      begin
        source = Source.load(file)
      rescue ::SystemCallError => e
        return capture_error(Source.new(string: "", file:, line: 1), e)
      end

      execute_source(source, require:, receiver:, &block)
    end

    def self.capture_error(source, error)
      acquired = STATE.trap
      scope = STATE.create
      scope.capture(source, error).result
    ensure
      STATE.restore if acquired
      STATE.shutdown(scope) if scope
    end

    def self.execute_source(source, require:, receiver:, &block)
      acquired = false
      return Result.new(value: nil, error: nil, stack: []) if source.string.empty? && require.nil?

      acquired = STATE.trap
      scope = STATE.create
      catch(:result) { run_source(scope, source, require, receiver, &block) }
      scope.result

    ensure
      STATE.restore if acquired
      STATE.shutdown(scope) if scope
    end

    def self.run_source(scope, source, library, receiver, &block)
      ::Kernel.require(library) if library
      scope.call(source, receiver, &block)
    rescue ::LoadError => e
      scope.capture(source, e)
    end

    def self.validate_context!(library, receiver)
      ArgumentError.("Executor library must be a String or nil") unless library.nil? || library.is_a?(::String)

      valid = (receiver in ::Object) && receiver.respond_to?(:public_send) && receiver.respond_to?(:instance_exec)
      ArgumentError.("Executor receiver must be an executable Object or nil") unless valid
    end

    def self.validate_source!(string, file, line)
      ArgumentError.("Executor source must be a String") unless string.is_a?(::String)
      ArgumentError.("Executor file must be a String or nil") unless file.nil? || file.is_a?(::String)

      valid = line.nil? || (line.is_a?(::Integer) && line.between?(1, SOURCE_LINE_MAX))
      ArgumentError.("Executor line must be between 1 and #{SOURCE_LINE_MAX}") unless valid
    end

    private_class_method(
      :capture_error,
      :execute_source,
      :load,
      :run_source,
      :validate_context!,
      :validate_source!
    )
  end

end
