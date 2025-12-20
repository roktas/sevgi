# frozen_string_literal: true

require "open3"

module Sevgi
  module Function
    module Shell
      Result = Struct.new(:args, :outs, :errs, :exit_code) do
        def all     = [ *outs, "\n\n", *errs ].join("\n").strip
        def cmd     = args.join(" ")
        def err     = errs.join("\n")
        def notok?  = !ok?
        def ok?     = exit_code&.zero?
        def out     = outs.join("\n")
        def outline = outs.first

        def self.dummy = new([], [], [], 0)
      end

      # Adapted to popen3 from github.com/mina-deploy/mina
      class Runner
        def initialize
          @coathooks = 0
        end

        def call(*args, &block) # rubocop:disable Metrics/MethodLength
          return Result.dummy if args.empty?

          outs, errs, status =
            Open3.popen3(*args) do |stdin, stdout, stderr, wait_thread|
              if block
                input = block.call
                stdin.write(block.call) if input
                stdin.close
              end

              block(stdout, stderr, wait_thread)
            end
          Result.new(args, outs, errs, status.exitstatus)
        end

        private

          def block(stdout, stderr, wait_thread)
            # Handle `^C`
            trap("INT") { handle_sigint(wait_thread.pid) }

            outs = stdout.readlines.map(&:chomp)
            errs = stderr.readlines.map(&:chomp)

            [ outs, errs, wait_thread.value ]
          end

          def handle_sigint(pid) # rubocop:disable Metrics/MethodLength
            message, signal =
              if @coathooks > 1
                [ "SIGINT received again. Force quitting...", "KILL" ]
              else
                [ "SIGINT received.", "TERM" ]
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

      def sh!(...)
        sh(...).tap do |result|
          unless result.ok?
            warn result.err
            warn ""

            fail "Command failed: #{result.cmd}"
          end
        end
      end
    end

    extend Shell
  end
end
