# frozen_string_literal: true

require "singleton"

require_relative "executor/error"
require_relative "executor/scope"
require_relative "executor/source"

module Sevgi
  class Executor
    include Singleton

    def self.load(file, ...)
      PanicError.("box stack empty; create a box first") unless instance.current

      instance.current.load(file, ...)
    end

    def self.execute(string, file: nil, line: nil, require: nil, receiver: nil, &block)
      return if string.empty?

      Signal.trap("INT") { Kernel.abort("") }

      ::Kernel.require(require) if require

      catch(:result) do
        instance.create.call(Source.new(string:, file:, line:), receiver, &block)
      end
    ensure
      instance.shutdown
    end

    def self.execute_file(file, require: nil, receiver: nil, &block)
      execute(::File.read(file), file: file, line: 1, require:, receiver:, &block)
    end

    def self.shutdown
      instance.shutdown
    end

    def initialize          = @scopes = []

    def create(scope = nil) = Scope.new(scope).tap { @scopes << it }

    def current             = @scopes.last

    def shutdown            = @scopes.pop
  end
end
