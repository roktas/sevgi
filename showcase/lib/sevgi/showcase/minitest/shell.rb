# frozen_string_literal: true

require "open3"
require "sevgi/function"

module Sevgi
  # Minitest helpers used by the showcase component.
  # @api private
  module Test
    # Shell runner helpers for showcase tests.
    # @api private
    module Shell
      # Shared process-global SIGINT coordinator.
      # @api private
      SignalCoordinator = ::Sevgi::Function::Shell.const_get(:SignalCoordinator, false)

      private_constant :SignalCoordinator

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
        # @yield optional stdin writer evaluated with stdin as receiver
        # @yieldreturn [Object]
        # @return [Sevgi::Test::Shell::Result]
        # @raise [StandardError] when the input block raises; the child is terminated and reaped before propagation
        # @note The first SIGINT sends TERM and the second sends KILL outside trap context. The handler is restored after
        #   the last active run.
        def run(*args, &block)
          @coathooks = 0
          out, err, status = Open3.popen3(*args) do |stdin, stdout, stderr, thread|
            capture(stdin, stdout, stderr, thread, &block)
          end

          Result[args, out, err, status.exitstatus]
        end

        private

        # rubocop:disable Lint/RescueException
        def capture(stdin, stdout, stderr, thread, &block)
          register_capture(thread)
          registered = true
          readers = outputs(stdout, stderr)

          collect_capture(stdin, thread, readers, &block)
        rescue Exception
          cleanup_failed_capture(stdin, thread, readers)
          raise
        ensure
          finish_capture(stdin, registered)
        end
        # rubocop:enable Lint/RescueException

        def finish_capture(stdin, registered)
          close_input(stdin)
          SignalCoordinator.unregister(self) if registered
        end

        def register_capture(thread)
          SignalCoordinator.register(self, thread.pid)
        end

        def cleanup_failed_capture(stdin, thread, readers)
          close_input(stdin)
          stop_process(thread)
          Array(readers).each(&:join)
        end

        def close_input(stdin)
          stdin.close unless stdin.closed?
        rescue IOError
          nil
        end

        def collect_capture(stdin, thread, readers, &block)
          inputs(stdin, thread, &block)
          close_input(stdin)

          [readers[0].value, readers[1].value, thread.value]
        end

        def handle_sigint(pid)
          @coathooks += 1
          message, signal = if @coathooks > 1
            ["SIGINT received again. Force quitting...", "KILL"]
          else
            ["SIGINT received.", "TERM"]
          end

          warn("\n#{message}")
          ::Process.kill(signal, pid)
        rescue Errno::ESRCH
          warn("No process to kill.")
        end

        def inputs(stdin, thread, &block)
          stdin.instance_exec(thread, &block) if block
        end

        def kill_process(signal, pid)
          ::Process.kill(signal, pid)
        rescue Errno::ESRCH
          nil
        end

        def outputs(stdout, stderr)
          [
            Thread.new { stdout.readlines.map(&:chomp) },
            Thread.new { stderr.readlines.map(&:chomp) }
          ]
        end

        def stop_process(thread)
          return unless thread&.alive?

          kill_process("TERM", thread.pid)
          return if thread.join(1)

          kill_process("KILL", thread.pid)
          thread.join
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
