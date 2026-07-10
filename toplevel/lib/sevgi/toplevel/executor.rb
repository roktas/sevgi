# frozen_string_literal: true

require "sevgi/executor"

module Sevgi
  BootBlock = proc { send(is_a?(::Module) ? :extend : :include, ::Sevgi) }

  private_constant :BootBlock

  # Executes Sevgi script source with the full top-level DSL installed.
  # @param args [Array] arguments forwarded to {Sevgi::Executor.execute}
  # @param kwargs [Hash] keyword arguments forwarded to {Sevgi::Executor.execute}
  # @return [Sevgi::Executor::Scope, nil] execution result, or nil for empty source
  # @note Required-library load failures are captured as {Sevgi::Executor::Error} on the returned scope.
  # @note Reentrant and concurrent calls keep independent executor scope stacks per fiber.
  # @see Sevgi::Executor.execute
  def self.execute(*args, **kwargs) = Executor.execute(*args, **kwargs, &BootBlock)

  # Executes a Sevgi script file with the full top-level DSL installed.
  # @param args [Array] arguments forwarded to {Sevgi::Executor.execute_file}
  # @param kwargs [Hash] keyword arguments forwarded to {Sevgi::Executor.execute_file}
  # @return [Sevgi::Executor::Scope, nil] execution result, or nil for an empty file
  # @note File-read and required-library load failures are captured as {Sevgi::Executor::Error} on the returned scope.
  # @note Reentrant and concurrent calls keep independent executor scope stacks per fiber.
  # @see Sevgi::Executor.execute_file
  def self.execute_file(*args, **kwargs) = Executor.execute_file(*args, **kwargs, &BootBlock)

  module Toplevel
    # Loads one or more Sevgi files relative to the caller's source file.
    # @param files [Array<String>] Sevgi script files to locate and execute
    # @return [Array<String>] the input file list
    # @raise [Sevgi::PanicError] when called without an active executor scope
    # @raise [Sevgi::Error] when a file cannot be located
    # @note `Load` resolves against the active executor scope in the current fiber.
    def Load(*files)
      start = ::File.dirname(caller_locations(1..1).first.path)

      files.each do |file|
        location = F.locate(file, start)

        ::Sevgi::Executor.load(location.file)
      end
    end
  end
end
