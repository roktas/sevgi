# frozen_string_literal: true

require "open3"

module Sevgi
  module Function
    module Shell
      def executable?(program)
        program = program.to_s
        return false if program.empty?

        executable_cache.fetch(program) do
          executable_cache[program] = ENV.fetch("PATH", "").split(::File::PATH_SEPARATOR).any? do |dir|
            ::File.executable?(::File.join(dir, program))
          end
        end
      end

      def executable!(*args)
        program = args.first.to_s.split.first
        Error.("Missing executable: #{program}") unless executable?(program)
      end

      Result = Struct.new(:args, :outs, :errs, :exit_code) do
        def all = [*outs, "\n\n", *errs].join("\n").strip
        def cmd = args.join(" ")
        def err = errs.join("\n")
        def notok? = !ok?
        def ok? = exit_code&.zero?
        def out = outs.join("\n")
        def outline = outs.first

        def self.dummy = new([], [], [], 0)
      end

      # Adapted to popen3 from github.com/mina-deploy/mina
      class Runner
        def initialize
          @coathooks = 0
        end

        def call(*args, &input)
          return Result.dummy if args.empty?

          outs, errs, status = Open3.popen3(*args) do |stdin, stdout, stderr, wait_thread|
            content = input.call if input
            stdin.write(content) if content
            stdin.close

            capture(stdout, stderr, wait_thread)
          end

          Result.new(args, outs, errs, status.exitstatus)
        end

        private

        def capture(stdout, stderr, wait_thread)
          # Handle `^C`
          previous = trap("INT") { handle_sigint(wait_thread.pid) }

          outs = Thread.new { stdout.readlines.map(&:chomp) }
          errs = Thread.new { stderr.readlines.map(&:chomp) }

          [outs.value, errs.value, wait_thread.value]
        ensure
          trap("INT", previous) if previous
        end

        def handle_sigint(pid)
          message, signal = if @coathooks > 1
            ["SIGINT received again. Force quitting...", "KILL"]
          else
            ["SIGINT received.", "TERM"]
          end

          warn
          warn(message)
          ::Process.kill(signal, pid)
          @coathooks += 1
        rescue Errno::ESRCH
          warn("No process to kill.")
        end
      end

      def sh(...) = Runner.new.(...)

      def sh!(*args, &block)
        executable!(*args) unless args.empty?

        sh(*args, &block).tap do |result|
          unless result.ok?
            warn(result.err)
            warn("")

            Error.("Command failed: #{result.cmd}")
          end
        end
      end

      private

      def executable_cache = @executable_cache ||= {}
    end

    extend Shell
  end
end
