# frozen_string_literal: true

module Sevgi
  class Executor
    # Describes Ruby source evaluated by the Sevgi executor.
    # @api private
    Source = Data.define(:string, :file, :line) do
      # @overload call(string:, file: nil, line: nil)
      #   Builds a source object.
      #   @param string [String] Ruby source string
      #   @param file [String, nil] source file name for diagnostics
      #   @param line [Integer, nil] starting source line for diagnostics
      #   @return [Sevgi::Executor::Source] source object
      def self.call(...) = new(...)

      # Builds a source object from a file.
      # @param file [String] source file to read
      # @return [Sevgi::Executor::Source] source object with file contents
      # @raise [Errno::ENOENT] when the file cannot be read
      def self.load(file) = new(string: ::File.read(file), file: file, line: 1)

      # Creates a source object.
      # @param string [String] Ruby source string
      # @param file [String, nil] source file name for diagnostics
      # @param line [Integer, nil] starting source line for diagnostics
      # @return [void]
      def initialize(string:, file: nil, line: nil) = super(string:, file: file || "sevgi", line: line || 1)

      # Returns the stack key used for this source.
      # @return [String] source file name
      def key = file
    end
  end
end
