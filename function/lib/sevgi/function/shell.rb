# frozen_string_literal: true

require "open3"
require "shellwords"

module Sevgi
  module Function
    # Shell execution helpers and executable lookup utilities.
    module Shell
      # Checks whether a program exists and is executable.
      # @param program [Object] program name, absolute path, or relative slash-containing path
      # @return [Boolean] true when an executable regular file is found
      # @note PATH is evaluated on every call; empty PATH segments mean the current directory.
      def executable?(program)
        program = program.to_s
        return false if program.empty?
        return executable_file?(program) if slash_path?(program)

        ENV.fetch("PATH", "").split(::File::PATH_SEPARATOR, -1).any? do |dir|
          executable_file?(::File.join(dir.empty? ? "." : dir, program))
        end
      end

      # Requires the first command argument to name an executable program.
      # @param args [Array<Object>] command arguments
      # @return [nil]
      # @raise [Sevgi::Error] when the program cannot be found in PATH
      # @note The first argument is checked as one exact argv entry; it is never shell-split.
      def executable!(*args)
        program = args.first.to_s
        Error.("Missing executable: #{program}") unless executable?(program)
      end

      # Immutable result returned by shell commands.
      #
      # @example Inspect a command result
      #   require "rbconfig"
      #   result = Sevgi::F.sh(RbConfig.ruby, "-e", "puts 42")
      #   result.ok?     # => true
      #   result.outline # => "42"
      Result = Data.define(:args, :outs, :errs, :exit_code, :signal) do
        # @!attribute [r] args
        #   @return [Array<String>] frozen command arguments
        # @!attribute [r] outs
        #   @return [Array<String>] frozen captured stdout lines
        # @!attribute [r] errs
        #   @return [Array<String>] frozen captured stderr lines
        # @!attribute [r] exit_code
        #   @return [Integer, nil] process exit code
        # @!attribute [r] signal
        #   @return [Integer, nil] terminating signal number

        # Creates an owned result snapshot.
        # @param args [Array<Object>] command arguments
        # @param outs [Array<String>] captured stdout lines
        # @param errs [Array<String>] captured stderr lines
        # @param exit_code [Integer, nil] process exit code
        # @param signal [Integer, nil] terminating signal number
        # @return [void]
        def initialize(args:, outs:, errs:, exit_code:, signal:)
          super(
            args: args.map { it.to_s.dup.freeze }.freeze,
            outs: outs.map { it.dup.freeze }.freeze,
            errs: errs.map { it.dup.freeze }.freeze,
            exit_code:,
            signal:
          )
        end

        private_class_method :[]

        # Returns captured output with one blank line between non-empty streams.
        # Captured lines are joined with one newline and are not otherwise trimmed.
        # @example Combine standard output and standard error
        #   result = Sevgi::Function::Shell::Result.new(
        #     args: ["tool"], outs: ["output"], errs: ["warning"], exit_code: 0, signal: nil
        #   )
        #   result.all # => "output\n\nwarning"
        # @return [String] combined output, or an empty string when neither stream contains lines
        def all
          return err if outs.empty?
          return out if errs.empty?

          "#{out}\n\n#{err}"
        end

        # Returns the command as a shell-like display string.
        # @return [String]
        def cmd = ::Shellwords.join(args)

        # Returns captured stderr as a string.
        # @return [String]
        def err = errs.join("\n")

        # Reports whether the command failed.
        # @return [Boolean]
        def notok? = !ok?

        # Reports whether the command exited successfully.
        # @return [Boolean]
        def ok? = !exit_code.nil? && exit_code.zero?

        # Returns captured stdout as a string.
        # @return [String]
        def out = outs.join("\n")

        # Returns the first stdout line.
        # @return [String, nil]
        def outline = outs.first

        # Reports whether the command was terminated by a signal.
        # @return [Boolean]
        def signaled? = !signal.nil?
      end

      # Shared process-global SIGINT state for overlapping shell runners.
      # @api private
      module Signals
        Entry = Data.define(:runner, :pid) do
          private_class_method :[]
        end

        WAKE = "."

        private_constant :WAKE

        class << self
          def register(runner, pid)
            mutex.synchronize do
              install unless entries.any?
              entries[runner] = Entry.new(runner, pid)
            end
          end

          def unregister(runner)
            worker = mutex.synchronize do
              next unless entries.delete(runner)

              restore unless entries.any?
            end

            worker.join if worker && worker != Thread.current
          end

          private

          def dispatch
            active = mutex.synchronize { entries.values.dup }
            active.each { dispatch_entry(it) }
          end

          def dispatch_entry(entry)
            entry.runner.send(:handle_sigint, entry.pid)
          rescue ::StandardError => e
            warn("SIGINT dispatch failed: #{e.message}")
          end

          def install
            reader, writer = ::IO.pipe
            worker = Thread.new { listen(reader) }
            previous = Signal.trap("INT") { notify(writer) }

            @previous = previous
            @worker = worker
            @writer = writer
          rescue ::StandardError
            Signal.trap("INT", previous) if previous
            close_io(writer)
            worker&.join
            close_io(reader)
            raise
          end

          def listen(reader)
            dispatch while reader.read(1)
          rescue ::IOError, ::SystemCallError
            nil
          ensure
            close_io(reader)
          end

          def mutex = @mutex ||= Mutex.new

          def entries = @entries ||= {}

          def notify(writer)
            writer.write_nonblock(WAKE, exception: false)
          rescue ::IOError, ::SystemCallError
            nil
          end

          def restore
            Signal.trap("INT", @previous)
            @previous = nil

            writer = @writer
            worker = @worker
            @worker = nil
            @writer = nil
            close_io(writer)
            worker
          end

          def close_io(io)
            io&.close unless io&.closed?
          rescue ::IOError
            nil
          end
        end
      end

      private_constant :Signals

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
        # @raise [Sevgi::ArgumentError] when no command is given
        # @raise [Errno::ENOENT] when the executable cannot be spawned
        def call(*args, &input)
          ArgumentError.("Shell command required") if args.empty?

          @coathooks = 0
          outs, errs, status = Open3.popen3(*args) do |stdin, stdout, stderr, wait_thread|
            capture(stdin, stdout, stderr, wait_thread, &input)
          end

          Result.new(args:, outs:, errs:, exit_code: status.exitstatus, signal: status.termsig)
        end

        private

        # rubocop:disable Lint/RescueException
        def capture(stdin, stdout, stderr, wait_thread, &input)
          registered = false
          Signals.register(self, wait_thread.pid)
          registered = true
          readers = start_readers(stdout, stderr)

          read_process(stdin, wait_thread, readers, &input)
        rescue Exception
          cleanup_failed_capture(stdin, wait_thread, readers)
          raise
        ensure
          close_input(stdin)
          Signals.unregister(self) if registered
        end
        # rubocop:enable Lint/RescueException

        def start_readers(stdout, stderr)
          [
            Thread.new { stdout.readlines.map(&:chomp) },
            Thread.new { stderr.readlines.map(&:chomp) }
          ]
        end

        def read_process(stdin, wait_thread, readers, &input)
          write_input(stdin, &input)
          close_input(stdin)

          status = wait_thread.value

          [readers[0].value, readers[1].value, status]
        end

        def cleanup_failed_capture(stdin, wait_thread, readers)
          close_input(stdin)
          stop_process(wait_thread)
          join_readers(readers)
        end

        def handle_sigint(pid)
          @coathooks += 1

          message, signal = if @coathooks > 1
            ["SIGINT received again. Force quitting...", "KILL"]
          else
            ["SIGINT received.", "TERM"]
          end

          warn
          warn(message)
          ::Process.kill(signal, pid)
        rescue Errno::ESRCH
          warn("No process to kill.")
        end

        def write_input(stdin)
          return unless block_given?

          content = yield
          stdin.write(content) if content
        end

        def close_input(stdin)
          stdin.close unless stdin.closed?
        rescue IOError
          nil
        end

        def stop_process(wait_thread)
          return unless wait_thread&.alive?

          kill_process("TERM", wait_thread.pid)
          return if wait_thread.join(1)

          kill_process("KILL", wait_thread.pid)
          wait_thread.join
        end

        def kill_process(signal, pid)
          ::Process.kill(signal, pid)
        rescue Errno::ESRCH
          nil
        end

        def join_readers(readers)
          Array(readers).each(&:join)
        end
      end

      private_constant :Runner

      # @overload sh(*args, &block)
      #   Runs a command and captures stdout, stderr, and exit status.
      #   @param args [Array<String>] command and arguments
      #   @yield optional stdin producer, evaluated once after output readers start
      #   @yieldreturn [String, nil] content to write to stdin; nil writes nothing
      #   @return [Sevgi::Function::Shell::Result]
      #   @raise [Sevgi::ArgumentError] when no command is given
      #   @raise [SystemCallError] when the executable cannot be spawned or process pipes cannot be opened
      #   @raise [StandardError] when the input block raises; the child is terminated and reaped before propagation
      #   @note The child's stdin is closed after the input block. During execution, the first SIGINT sends TERM to the
      #     child process and the second SIGINT as KILL to each active child outside trap context, then restores the
      #     previous handler.
      def sh(...) = Runner.new.(...)

      # Runs a command, requiring both executable lookup and successful exit status.
      # @param args [Array<String>] command and arguments
      # @yield optional stdin producer, evaluated once after output readers start
      # @yieldreturn [String, nil] content to write to stdin; nil writes nothing
      # @return [Sevgi::Function::Shell::Result]
      # @raise [Sevgi::ArgumentError] when no command is given
      # @raise [Sevgi::Error] when the executable is missing or the command fails
      # @raise [SystemCallError] when the executable cannot be spawned or process pipes cannot be opened
      # @raise [StandardError] when the input block raises; the child is terminated and reaped before propagation
      # @note The child's stdin is closed after the input block. During execution, the first SIGINT sends TERM to the
      #   child process and the second SIGINT as KILL to each active child outside trap context, then restores the previous
      #   handler.
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

      def executable_file?(path)
        ::File.file?(path) && ::File.executable?(path)
      end

      def slash_path?(program)
        program.include?(::File::SEPARATOR) || (::File::ALT_SEPARATOR && program.include?(::File::ALT_SEPARATOR))
      end
    end

    extend Shell
  end
end
