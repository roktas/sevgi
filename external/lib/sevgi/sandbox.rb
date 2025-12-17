# frozen_string_literal: true

require "singleton"

module Sevgi
  class Sandbox
    include Singleton

    Error = Class.new(Sevgi::Error)

    def self.run(file, ...)
      instance.create.load(file, ...)
    ensure
      instance.shutdown
    end

    def self.load(file, ...)
      instance.create unless instance.current
      instance.current.load(file, ...)
    end

    def self.load!(file, ...)
      Error.("Box stack empty; create a Box first") unless instance.current

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

    def create
      Box.new.tap { @sandboxes << it }
    end

    def shutdown
      @sandboxes.pop
    end

    class Box
      def initialize
        @module = Module.new
        @loaded = {}
      end

      def load(file, receiver = Undefined, &preblock)
        return if @loaded[file = F.existing!(file, extensions: [ EXTENSION ])]

        Undefined.default(receiver, TOPLEVEL_BINDING.receiver).instance_exec(@module, &preblock) if preblock

        ::Kernel.load(file, @module) and (@loaded[file] = true)
      rescue Exception => e # rubocop:disable Lint/RescueException
        warn(description(e, file))
        raise(e)
      end

      private

        def description(e, file)
          case e
          when ValidationError then "Validation error"
          else                      "Error"
          end => error

          <<~DESCRIPTION
            #{error} #{context(e.backtrace, file)}
              #{e.message}
          DESCRIPTION
        end

        def context(backtrace, file)
          default = "in file '#{file}'"
          return default unless backtrace

          path = ::File.expand_path(file)
          _, line = backtrace.map { it.split(":")[..1] }.find do |spot|
            ::File.expand_path(spot.first) == path
          end

          line ? "in file '#{file}', around line #{line}" : default
        end
    end
  end
end
