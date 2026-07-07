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
  # whenever possible.
  class Executor
    include Singleton

    # Loads a script file inside the current executor scope.
    # @param file [String] path to a Sevgi script file
    # @return [Sevgi::Executor::Scope] current execution scope
    # @raise [Sevgi::PanicError] when there is no active executor scope
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
    # @raise [LoadError] when the optional required library cannot be loaded
    def self.execute(string, file: nil, line: nil, require: nil, receiver: nil, &block)
      return if string.empty?

      interrupt = Signal.trap("INT") { Kernel.abort("") }

      ::Kernel.require(require) if require

      scope = instance.create
      catch(:result) { scope.call(Source.new(string:, file:, line:), receiver, &block) }

    ensure
      Signal.trap("INT", interrupt) if interrupt
      instance.shutdown if scope
    end

    # Executes a file inside a managed Sevgi script scope.
    # @param file [String] source file to read and execute
    # @param require [String, nil] optional Ruby library to require before execution
    # @param receiver [Object, nil] receiver used while booting the DSL
    # @yield optional boot block that installs DSL methods before evaluation
    # @yieldreturn [void]
    # @return [Sevgi::Executor::Scope, nil] execution scope, or nil for an empty file
    # @raise [Errno::ENOENT] when the file cannot be read
    # @raise [LoadError] when the optional required library cannot be loaded
    def self.execute_file(file, require: nil, receiver: nil, &block)
      execute(::File.read(file), file: file, line: 1, require:, receiver:, &block)
    end

    # Removes the current executor scope.
    # @return [Sevgi::Executor::Scope, nil] removed scope
    # @api private
    def self.shutdown
      instance.shutdown
    end

    def initialize = @scopes = []

    # Creates and pushes a new executor scope.
    # @param scope [Module, nil] existing module scope to reuse
    # @return [Sevgi::Executor::Scope] created scope
    # @api private
    def create(scope = nil) = Scope.new(scope).tap { @scopes << it }

    # Returns the active executor scope.
    # @return [Sevgi::Executor::Scope, nil] active scope, if any
    # @api private
    def current = @scopes.last

    # Removes the active executor scope.
    # @return [Sevgi::Executor::Scope, nil] removed scope
    # @api private
    def shutdown = @scopes.pop
  end
end
