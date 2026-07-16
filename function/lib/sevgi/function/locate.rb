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
    Location = Data.define(:file, :slug, :dir) do
      # Creates an owned immutable location snapshot.
      # @param file [String] absolute matching file path
      # @param slug [String] candidate path that matched
      # @param dir [String] directory where the match was found
      # @return [void]
      def initialize(file:, slug:, dir:)
        super(file: file.dup.freeze, slug: slug.dup.freeze, dir: dir.dup.freeze)
      end

      private_class_method :[]
    end

    # Locates one of several candidate files by walking upward from an immutable configuration snapshot. Each call
    # observes the filesystem again and returns an owned immutable {Location} snapshot.
    class Locate
      # @overload call(paths, start = Dir.pwd, exclude: nil, &block)
      #   Builds a locator and runs it.
      #   @param paths [Array<String>, String] candidate file paths
      #   @param start [String] directory where lookup starts
      #   @param exclude [Array<String>, String, nil] paths ignored during lookup
      #   @yield optional matcher used instead of built-in file checks
      #   @yieldparam path [String] candidate path
      #   @yieldreturn [Boolean]
      #   @return [Sevgi::Function::Location, nil] found location, or nil
      def self.call(*, **, &block) = new(*, **).call(&block)

      # Returns the frozen owned candidate paths.
      # @return [Array<String>] frozen candidate path strings
      attr_reader :paths

      # Returns the frozen absolute start directory.
      # @return [String] frozen absolute path
      attr_reader :start

      # Returns the frozen owned paths ignored during lookup.
      # @return [Array<String>, nil] frozen absolute path strings, or nil
      attr_reader :exclude

      # Builds an upward file locator.
      # @param paths [Array<String>, String] candidate file paths
      # @param start [String] directory where lookup starts, expanded without changing process cwd
      # @param exclude [Array<String>, String, nil] paths ignored during lookup after absolute expansion
      # @return [void]
      def initialize(paths, start = ::Dir.pwd, exclude: nil)
        @paths = Array(paths).map { it.dup.freeze }.freeze
        @start = ::File.expand_path(start).freeze
        @exclude = [*exclude].map { ::File.expand_path(it).freeze }.freeze unless exclude.nil?
        freeze
      end

      # Runs the upward lookup.
      # @yield optional matcher used instead of built-in file checks
      # @yieldparam path [String] absolute candidate path
      # @yieldreturn [Boolean]
      # @note Absolute exclusions are applied before the default or custom matcher.
      # @return [Sevgi::Function::Location, nil] found location, or nil
      # @raise [Errno::ENOENT] when the start directory does not exist
      # @raise [Errno::ENOTDIR] when the start path is not a directory
      def call(&block)
        validate_start!

        each_parent(start) do |here|
          next unless (found = match(here, &block))

          slug, file = found

          return Location.new(file:, slug:, dir: here)
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
          next if excluded?(candidate)

          matched = block ? block.call(candidate) : ::File.file?(candidate)
          return [path, candidate] if matched
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
