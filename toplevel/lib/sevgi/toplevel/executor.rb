# frozen_string_literal: true

require "sevgi/executor"

module Sevgi
  BootBlock = proc { send(is_a?(::Module) ? :extend : :include, ::Sevgi) }

  private_constant :BootBlock

  # Executes Sevgi script source with the full top-level DSL installed.
  #
  # @example Execute source in an isolated scope
  #   result = Sevgi.execute("F.pluralize('cat')")
  #   result.value # => "cats"
  # @param string [String] source to evaluate
  # @param file [String, nil] source file name used for errors and backtraces
  # @param line [Integer, nil] starting source line used for errors and backtraces
  # @param require [String, nil] optional Ruby library to require before execution
  # @param main [Boolean] whether to install the DSL through Ruby's top-level main object
  # @return [Sevgi::Executor::Result] immutable execution result
  # @raise [Sevgi::ArgumentError] when source, file, line, required library, or main mode is invalid
  # @note Script and required-library failures are captured in {Sevgi::Executor::Result#error}.
  # @note The default isolated mode does not modify Ruby's top-level main object. `main: true` preserves the command-line
  #   default by installing Sevgi through main before evaluating source in the managed script scope.
  # @note Empty source without `require:` is a strict no-op; the DSL boot block is unused.
  # @note Reentrant and concurrent calls keep independent executor scope stacks per fiber.
  # @see https://sevgi.roktas.dev/execution/ Execution guide
  def self.execute(string, file: nil, line: nil, require: nil, main: false)
    Executor.__send__(:execute, string, file:, line:, require:, receiver: execution_receiver(main), &BootBlock)
  end

  # Executes a Sevgi script file with the full top-level DSL installed.
  # @param file [String] source file to read and execute
  # @param as [String, nil] source basename used for evaluation, diagnostics, and caller-derived output defaults;
  #   its extension is replaced with `.sevgi` and the input file's directory is retained
  # @param require [String, nil] optional Ruby library to require before execution
  # @param main [Boolean] whether to install the DSL through Ruby's top-level main object
  # @return [Sevgi::Executor::Result] immutable execution result
  # @raise [Sevgi::ArgumentError] when file, logical source name, required library, or main mode is invalid
  # @note File-read, script, and required-library failures are captured in {Sevgi::Executor::Result#error}.
  # @note The default isolated mode does not modify Ruby's top-level main object. `main: true` preserves the command-line
  #   default by installing Sevgi through main before evaluating source in the managed script scope.
  # @note An empty file without `require:` is a strict no-op; the DSL boot block is unused.
  # @note Reentrant and concurrent calls keep independent executor scope stacks per fiber.
  # @see https://sevgi.roktas.dev/execution/ Execution guide
  def self.execute_file(file, as: nil, require: nil, main: false)
    as = source_name(file, as) if as
    Executor.__send__(:execute_file, file, as:, require:, receiver: execution_receiver(main), &BootBlock)
  end

  def self.execution_receiver(main)
    ArgumentError.("Sevgi main mode must be true or false") unless [true, false].include?(main)

    TOPLEVEL_BINDING.receiver if main
  end

  def self.source_name(file, name)
    ArgumentError.("Sevgi file must be a String") unless file.is_a?(::String)
    ArgumentError.("Sevgi file name must be a non-empty String") unless name.is_a?(::String) && !name.empty?
    ArgumentError.("Sevgi file name must not include a directory") unless ::File.basename(name) == name

    ::File.join(::File.dirname(file), F.subext(".sevgi", name))
  end

  private_class_method :execution_receiver, :source_name

  module Toplevel
    # Loads one or more Sevgi files relative to the caller's source file.
    # @param files [Array<String>] Sevgi script files to locate and execute
    # @return [Array<String>] the input file list
    # @raise [Sevgi::PanicError] when called without an active executor scope
    # @raise [Sevgi::Error] when a file cannot be located
    # @note `Load` resolves against the active executor scope in the current fiber.
    # @note Ordinary library code should use Ruby `require`; `Load` is available only during Sevgi script execution.
    # @see Sevgi.Load
    # @see Sevgi.execute_file
    def Load(*files)
      start = ::File.dirname(caller_locations(1..1).first.path)

      files.each do |file|
        location = F.locate(file, start)

        ::Sevgi::Executor.__send__(:load, location.file)
      end
    end
  end
end
