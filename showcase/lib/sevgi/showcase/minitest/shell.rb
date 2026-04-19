# frozen_string_literal: true

require "open3"

module Sevgi
  module Test
    module Shell
      Result = Data.define(:args, :out, :err, :exit_code) do
        def cmd     = args.join(" ")

        def notok?  = !ok?

        def ok?     = exit_code&.zero?

        def outline = out.first

        def to_s    = out.join("\n")
      end

      # Adapted to popen3 from github.com/mina-deploy/mina
      class Runner
        def initialize
          @coathooks = 0
        end

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
            trap("INT") { handle_sigint(thread.pid) } # handle `^C`

            out = stdout.readlines.map(&:chomp)
            err = stderr.readlines.map(&:chomp)

            [ out, err, thread.value ]
          end

          def handle_sigint(pid)
            message, signal = if @coathooks > 1
              [ "SIGINT received again. Force quitting...", "KILL" ]
            else
              [ "SIGINT received.", "TERM" ]
            end

            warn("\n#{message}")
            ::Process.kill(signal, pid)
            @coathooks += 1
          rescue Errno::ESRCH
            warn("No process to kill.")
          end
      end

      extend self

      def run(...) = Runner.new.run(...)
    end
  end
end
