# frozen_string_literal: true

require "singleton"

require_relative "executor/error"
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
  class Executor
    include Singleton

    # Thread-current key used for the fiber-local executor scope stack.
    # @api private
    SCOPE_KEY = :sevgi_executor_scopes

    # Loads a script file inside the current executor scope.
    # @param file [String] path to a Sevgi script file
    # @return [Sevgi::Executor::Scope] current execution scope
    # @raise [Sevgi::PanicError] when there is no active executor scope
    # @note Uses the active executor scope from the current fiber.
    # @api private
    def self.load(file, ...)
      PanicError.("box stack empty; create a box first") unless instance.current

      instance.current.load(file, ...)
    end

    # Executes Ruby source inside a managed Sevgi script scope.
    # @param string [String] source to evaluate
    # @param file [String, nil] source file name used for errors and backtraces
    # @param line [Integer, nil] starting source line used for errors and backtraces
    # @param require [String, nil] optional Ruby library to require before execution
    # @param receiver [Object, nil] receiver used while booting the DSL
    # @yield optional boot block that installs DSL methods before evaluation
    # @yieldreturn [void]
    # @return [Sevgi::Executor::Scope, nil] execution scope, or nil for empty source
    # @note Required-library load failures are captured as {Sevgi::Executor::Error} on the returned scope.
    # @note Reentrant and concurrent calls keep independent scope stacks per fiber. The temporary SIGINT handler remains
    #   process-global while any execution is active.
    def self.execute(string, file: nil, line: nil, require: nil, receiver: nil, &block)
      execute_source(Source.new(string:, file:, line:), require:, receiver:, &block)
    end

    # Executes a file inside a managed Sevgi script scope.
    # @param file [String] source file to read and execute
    # @param require [String, nil] optional Ruby library to require before execution
    # @param receiver [Object, nil] receiver used while booting the DSL
    # @yield optional boot block that installs DSL methods before evaluation
    # @yieldreturn [void]
    # @return [Sevgi::Executor::Scope, nil] execution scope, or nil for an empty file
    # @note File-read and required-library load failures are captured as {Sevgi::Executor::Error} on the returned scope.
    # @note Reentrant and concurrent calls keep independent scope stacks per fiber. The temporary SIGINT handler remains
    #   process-global while any execution is active.
    def self.execute_file(file, require: nil, receiver: nil, &block)
      source = nil
      begin
        source = Source.load(file)
      rescue ::SystemCallError => e
        return capture_error(Source.new(string: "", file:, line: 1), e)
      end

      execute_source(source, require:, receiver:, &block)
    end

    # Removes the current executor scope.
    # @return [Sevgi::Executor::Scope, nil] removed scope
    # @api private
    def self.shutdown
      instance.shutdown
    end

    def initialize
      @signal_count = 0
      @signal_mutex = Mutex.new
      @signal_previous = nil
    end

    # Creates and pushes a new executor scope.
    # @param scope [Module, nil] existing module scope to reuse
    # @return [Sevgi::Executor::Scope] created scope
    # @api private
    def create(scope = nil) = Scope.new(scope).tap { scopes << it }

    # Returns the active executor scope.
    # @return [Sevgi::Executor::Scope, nil] active scope, if any
    # @api private
    def current = scopes.last

    # Restores the process SIGINT handler when the last active execution ends.
    # @return [void]
    # @api private
    def restore
      @signal_mutex.synchronize do
        next if @signal_count.zero?

        @signal_count -= 1
        next unless @signal_count.zero?

        Signal.trap("INT", @signal_previous)
        @signal_previous = nil
      end
    end

    # Removes the active executor scope.
    # @param scope [Sevgi::Executor::Scope, nil] exact scope to remove, or nil to pop the current scope
    # @return [Sevgi::Executor::Scope, nil] removed scope
    # @api private
    def shutdown(scope = nil)
      return scopes.pop unless scope
      return scopes.pop if scopes.last.equal?(scope)

      scopes.delete(scope)
    end

    # Installs the process SIGINT handler while one or more executions are active.
    # @return [void]
    # @api private
    def trap
      @signal_mutex.synchronize do
        @signal_previous = Signal.trap("INT") { Kernel.abort("") } if @signal_count.zero?

        @signal_count += 1
      end
    end

    def self.capture_error(source, error)
      instance.trap
      scope = instance.create
      scope.capture(source, error)
    ensure
      instance.restore
      instance.shutdown(scope) if scope
    end

    def self.execute_source(source, require:, receiver:, &block)
      return if source.string.empty?

      instance.trap
      scope = instance.create
      catch(:result) { run_source(scope, source, require, receiver, &block) }

    ensure
      instance.restore
      instance.shutdown(scope) if scope
    end

    def self.run_source(scope, source, library, receiver, &block)
      ::Kernel.require(library) if library
      scope.call(source, receiver, &block)
    rescue ::LoadError => e
      scope.capture(source, e)
    end

    private_class_method :capture_error, :execute_source, :run_source

    private

    def scopes = Thread.current[SCOPE_KEY] ||= []
  end
end
