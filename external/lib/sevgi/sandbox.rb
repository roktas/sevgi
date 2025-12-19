# frozen_string_literal: true

require "singleton"

module Sevgi
  class Sandbox
    include Singleton

    class Error < Sevgi::Error
      attr_reader :error, :box

      def initialize(error, box)
        @error = error
        @box   = box

        super(error.message)
      end

      def backtrace!
        error.backtrace
          .select { |line| stack.any? { line.start_with?(::File.expand_path(it)) } }
          .map    { |line| line.delete_prefix("#{::Dir.pwd}/") }
      end

      def stack = box.stack
    end

    DEFAULT_PROC = proc { include ::Sevgi::External }

    def self.run(file, require: nil, preload: nil, &block)
      Signal.trap("INT") { Kernel.abort("") }

      ::Kernel.require(require) if require
      ::Kernel.load(preload)    if preload

      if (error = catch(:error) { instance.create(file).load(file, &block || DEFAULT_PROC) }).is_a?(Error)
        raise(error)
      end

      true
    ensure
      instance.shutdown
    end

    def self.load(file, ...)
      PanicError.("box stack empty; create a box first") unless instance.current

      instance.current.load(file, ...)
    end

    def self.shutdown
      instance.shutdown
    end

    def initialize
      @sandboxes = []
    end

    def current
      @sandboxes.last
    end

    def create(file)
      Box.new(file).tap { @sandboxes << it }
    end

    def shutdown
      @sandboxes.pop
    end

    class Box
      attr_reader :file

      def initialize(file)
        @file   = file
        @module = Module.new
        @stack  = {}
      end

      def load(file, receiver = Undefined, &preblock)
        return if @stack[file = ::File.expand_path(F.existing!(file, extensions: [ EXTENSION ]))]

        @stack[file] = true

        Undefined.default(receiver, TOPLEVEL_BINDING.receiver).instance_exec(@module, &preblock) if preblock

        ::Kernel.load(file, @module)
      rescue Exception => e # rubocop:disable Lint/RescueException
        throw(:error, Sandbox::Error.new(e, self))
      end

      def stack = @stack.keys
    end
  end
end
