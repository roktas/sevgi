# frozen_string_literal: true

module Sevgi
  class Executor
    # Describes Ruby source evaluated by the Sevgi executor.
    # @api private
    Source = Data.define(:string, :file, :line, :origin) do
      # @overload call(string:, file: nil, line: nil, origin: nil)
      #   Builds a source object.
      #   @param string [String] Ruby source string
      #   @param file [String, nil] source file name for diagnostics
      #   @param line [Integer, nil] starting source line for diagnostics
      #   @param origin [String, nil] physical source path used for load-cycle identity
      #   @return [Sevgi::Executor::Source] source object
      def self.call(...) = new(...)

      # Builds a source object from a file.
      # @param file [String] source file to read
      # @param as [String, nil] logical source name used for evaluation and diagnostics
      # @return [Sevgi::Executor::Source] source object with file contents
      # @raise [Errno::ENOENT] when the file cannot be read
      def self.load(file, as: nil) = new(string: ::File.read(file), file: as || file, line: 1, origin: file)

      # Creates a source object.
      # @param string [String] Ruby source string
      # @param file [String, nil] source file name for diagnostics
      # @param line [Integer, nil] starting source line for diagnostics
      # @param origin [String, nil] physical source path used for load-cycle identity
      # @return [void]
      def initialize(string:, file: nil, line: nil, origin: nil)
        super(string:, file: file || "sevgi", line: line || 1, origin:)
      end

      private_class_method :[]

      # Returns the stack key used for this source.
      # @return [String] source file name
      def key = file

      # Returns the canonical identity used for active-load cycle detection.
      # @return [Integer, String] object identity for inline source, or canonical physical identity for loaded source
      def identity
        return object_id unless origin

        ::File.realpath(origin)
      rescue ::SystemCallError
        ::File.expand_path(origin)
      end
    end
  end
end
