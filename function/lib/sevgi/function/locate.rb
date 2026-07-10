# frozen_string_literal: true

module Sevgi
  module Function
    # Found file location returned by locate helpers.
    #
    # @!attribute [r] file
    #   @return [String] absolute matching file path
    # @!attribute [r] slug
    #   @return [String] candidate path that matched
    # @!attribute [r] dir
    #   @return [String] directory where the match was found
    Location = Data.define(:file, :slug, :dir)

    # Locates one of several candidate files by walking upward from a start directory.
    class Locate
      # @overload call(paths, start = Dir.pwd, exclude: nil, &block)
      #   Builds a locator and runs it.
      #   @param paths [Array<String>, String] candidate file paths
      #   @param start [String] directory where lookup starts
      #   @param exclude [Array<String>, String, nil] paths ignored during lookup
      #   @yield optional matcher used instead of file existence checks
      #   @yieldparam path [String] candidate path
      #   @yieldreturn [Boolean]
      #   @return [Sevgi::Function::Location, nil] found location, or nil
      def self.call(*, **, &block) = new(*, **).call(&block)

      # @!attribute [r] paths
      #   @return [Array<String>] candidate paths
      # @!attribute [r] start
      #   @return [String] absolute start directory
      # @!attribute [r] exclude
      #   @return [Array<String>, nil] expanded paths ignored during lookup
      attr_reader :paths, :start, :exclude

      # Builds an upward file locator.
      # @param paths [Array<String>, String] candidate file paths
      # @param start [String] directory where lookup starts, expanded without changing process cwd
      # @param exclude [Array<String>, String, nil] paths ignored during lookup after absolute expansion
      # @return [void]
      def initialize(paths, start = ::Dir.pwd, exclude: nil)
        @paths = Array(paths)
        @start = ::File.expand_path(start)
        @exclude = [*exclude].map { ::File.expand_path(it) } unless exclude.nil?
      end

      # Runs the upward lookup.
      # @yield optional matcher used instead of file existence checks
      # @yieldparam path [String] absolute candidate path
      # @yieldreturn [Boolean]
      # @return [Sevgi::Function::Location, nil] found location, or nil
      # @raise [Errno::ENOENT] when the start directory does not exist
      # @raise [Errno::ENOTDIR] when the start path is not a directory
      def call(&block)
        validate_start!

        each_parent(start) do |here|
          next unless (found = match(here, &block))

          slug, file = found

          return Location[file, slug, here]
        end
      end

      private

      def each_parent(here)
        loop do
          yield here

          parent = ::File.dirname(here)
          break if parent == here

          here = parent
        end
      end

      def excluded?(candidate)
        exclude&.include?(candidate)
      end

      def match(here, &block)
        paths.each do |path|
          candidate = ::File.expand_path(path, here)
          next if !block && excluded?(candidate)

          return [path, candidate] if (block || proc { ::File.exist?(it) }).call(candidate)
        end

        nil
      end

      def validate_start!
        raise ::Errno::ENOENT, start unless ::File.exist?(start)
        raise ::Errno::ENOTDIR, start unless ::File.directory?(start)
      end
    end

    # Locates a Sevgi-related file by walking upward from a start directory.
    # @param filename [String] file name or extensionless basename
    # @param start [String] directory where lookup starts
    # @param exclude [Array<String>, String, nil] paths ignored during lookup
    # @param extension [String] default extension added before lookup
    # @return [Sevgi::Function::Location] found location
    # @raise [Sevgi::Error] when no matching file exists
    def self.locate(filename, start, exclude: nil, extension: EXTENSION)
      Locate.(F.qualify(filename, extension), start, exclude:).tap do |path|
        Error.("Cannot load a file matching: #{filename}") unless path
      end
    end
  end
end
