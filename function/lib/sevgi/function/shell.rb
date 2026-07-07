# frozen_string_literal: true

require "open3"

module Sevgi
  module Function
    # Shell execution helpers and executable lookup utilities.
    module Shell
      # Checks whether a program exists in PATH.
      # @param program [Object] program name
      # @return [Boolean] true when an executable with this name is found
      def executable?(program)
        program = program.to_s
        return false if program.empty?

        executable_cache.fetch(program) do
          executable_cache[program] = ENV.fetch("PATH", "").split(::File::PATH_SEPARATOR).any? do |dir|
            ::File.executable?(::File.join(dir, program))
          end
        end
      end

      # Requires the first command argument to name an executable program.
      # @param args [Array<Object>] command arguments
      # @return [nil]
      # @raise [Sevgi::Error] when the program cannot be found in PATH
      def executable!(*args)
        program = args.first.to_s.split.first
        Error.("Missing executable: #{program}") unless executable?(program)
      end

      # Result object returned by shell commands.
      Result = Struct.new(:args, :outs, :errs, :exit_code) do
        # @!attribute [r] args
        #   @return [Array<String>] command arguments
        # @!attribute [r] outs
        #   @return [Array<String>] captured stdout lines
        # @!attribute [r] errs
        #   @return [Array<String>] captured stderr lines
        # @!attribute [r] exit_code
        #   @return [Integer, nil] process exit code

        # Returns stdout, a separator, and stderr as one string.
        # @return [String]
        def all = [*outs, "\n\n", *errs].join("\n").strip

        # Returns the command as a shell-like display string.
        # @return [String]
        def cmd = args.join(" ")

        # Returns captured stderr as a string.
        # @return [String]
        def err = errs.join("\n")

        # Reports whether the command failed.
        # @return [Boolean]
        def notok? = !ok?

        # Reports whether the command exited successfully.
        # @return [Boolean]
        def ok? = exit_code&.zero?

        # Returns captured stdout as a string.
        # @return [String]
        def out = outs.join("\n")

        # Returns the first stdout line.
        # @return [String, nil]
        def outline = outs.first

        # Builds a successful empty result.
        # @return [Sevgi::Function::Shell::Result]
        def self.dummy = new([], [], [], 0)
      end

      # Runs shell commands and captures stdout, stderr, and exit status.
      # @api private
      class Runner
        # Creates a shell runner.
        # @return [void]
        def initialize
          @coathooks = 0
        end

        # Runs a command and captures its output.
        # @param args [Array<String>] command and arguments
        # @yield optional content writer for stdin
        # @yieldreturn [String, nil]
        # @return [Sevgi::Function::Shell::Result]
        # @raise [Errno::ENOENT] when the executable cannot be spawned
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

      # @overload sh(*args, &block)
      #   Runs a command and captures stdout, stderr, and exit status.
      #   @param args [Array<String>] command and arguments
      #   @yield optional content writer for stdin
      #   @yieldreturn [String, nil]
      #   @return [Sevgi::Function::Shell::Result]
      #   @raise [Errno::ENOENT] when the executable cannot be spawned
      def sh(...) = Runner.new.(...)

      # Runs a command, requiring both executable lookup and successful exit status.
      # @param args [Array<String>] command and arguments
      # @yield optional content writer for stdin
      # @yieldreturn [String, nil]
      # @return [Sevgi::Function::Shell::Result]
      # @raise [Sevgi::Error] when the executable is missing or the command fails
      # @raise [Errno::ENOENT] when the executable cannot be spawned
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
