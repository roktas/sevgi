# frozen_string_literal: true

require "open3"

module Sevgi
  # Minitest helpers used by the showcase component.
  # @api private
  module Test
    # Shell runner helpers for showcase tests.
    # @api private
    module Shell
      # Shell command result.
      # @api private
      Result = Data.define(:args, :out, :err, :exit_code) do
        # Returns the command string.
        # @return [String]
        def cmd = args.join(" ")

        # Reports whether the command failed.
        # @return [Boolean]
        def notok? = !ok?

        # Reports whether the command exited successfully.
        # @return [Boolean]
        def ok? = exit_code&.zero?

        # Returns the first stdout line.
        # @return [String, nil]
        def outline = out.first

        # Returns stdout as a newline-joined string.
        # @return [String]
        def to_s = out.join("\n")
      end

      # Adapted to popen3 from github.com/mina-deploy/mina
      # Shell command runner.
      # @api private
      class Runner
        # Creates a runner.
        # @return [void]
        def initialize
          @coathooks = 0
        end

        # Runs a command and captures stdout, stderr, and exit status.
        # @param args [Array<String>] command and arguments
        # @return [Sevgi::Test::Shell::Result]
        def run(*args, &block)
          out, err, status = Open3.popen3(*args) do |stdin, stdout, stderr, thread|
            inputs(stdin, thread, &block) if block
            outputs(stdout, stderr, thread)
          end

          Result[args, out, err, status.exitstatus]
        end

        private

        def inputs(stdin, thread, &block)
          stdin.instance_exec(thread, &block)
          stdin.close unless stdin.closed?
        end

        def outputs(stdout, stderr, thread)
          # handle `^C`
          trap = trap("INT") { handle_sigint(thread.pid) }

          out = Thread.new { stdout.readlines.map(&:chomp) }
          err = Thread.new { stderr.readlines.map(&:chomp) }

          [out.value, err.value, thread.value]
        ensure
          trap("INT", trap) if trap
        end

        def handle_sigint(pid)
          message, signal = if @coathooks > 1
            ["SIGINT received again. Force quitting...", "KILL"]
          else
            ["SIGINT received.", "TERM"]
          end

          warn("\n#{message}")
          ::Process.kill(signal, pid)
          @coathooks += 1
        rescue Errno::ESRCH
          warn("No process to kill.")
        end
      end

      extend self

      # @overload run(*args)
      #   Runs a command through a fresh runner.
      #   @param args [Array<String>] command and arguments
      #   @return [Sevgi::Test::Shell::Result]
      def run(...) = Runner.new.run(...)
    end
  end
end
