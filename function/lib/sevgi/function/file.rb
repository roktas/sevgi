# frozen_string_literal: true

require "digest"
require "fileutils"

module Sevgi
  module Function
    # File-system helpers used by build scripts and DSL support code.
    module File
      # Checks whether a file would change if written with content.
      # @param file [String] file path to compare
      # @param content [String] proposed file content
      # @yield optional normalization filter applied to both old and new content
      # @yieldparam content [String] content to normalize
      # @yieldreturn [String]
      # @return [Boolean] true when the file is missing or content differs
      # @raise [Errno::EACCES] when the file cannot be read
      def changed?(file, content, &filter)
        return true unless ::File.exist?(file)

        old_content = ::File.read(file)
        old_content, content = [old_content, content].map(&filter) if filter

        Digest::SHA1.digest(old_content) != Digest::SHA1.digest(content)
      end

      # Finds an existing file by exact path or by trying default extensions.
      # @param file [String] file path or extensionless basename
      # @param extensions [Array<String>] extensions to try when file has no extension
      # @return [String, nil] matching file path, or nil when no file is found
      def existing(file, extensions)
        return file if ::File.exist?(file)
        return nil unless ::File.extname(file).empty?
        return nil if extensions.empty?

        extensions.map { |ext| "#{file}.#{ext}" }.detect { |file| ::File.exist?(file) }
      end

      # Finds an existing file or raises.
      # @param file [String] file path or extensionless basename
      # @param extensions [Array<String>] extensions to try when file has no extension
      # @return [String] matching file path
      # @raise [Sevgi::ArgumentError] when no matching file exists
      def existing!(file, extensions)
        existing(file, extensions).tap do |found|
          ArgumentError.("No matching file(s) found: #{file}") unless found
        end
      end

      # Maps each non-nil input file to an existing path lookup result.
      # @param files [Array<String, nil>] file paths or extensionless basenames
      # @param extensions [Array<String>] extensions to try when a file has no extension
      # @return [Hash{String => String, nil}] original file names mapped to found paths
      def existing_map(*files, extensions: [])
        {}.tap do |found|
          files.compact.each { |file| found[file] = existing(file, extensions) }
        end
      end

      # @overload existing_map!(*files, extensions: [])
      #   Maps each non-nil input file to an existing path lookup result or raises.
      #   @param files [Array<String, nil>] file paths or extensionless basenames
      #   @param extensions [Array<String>] extensions to try when a file has no extension
      #   @return [Hash{String => String}] original file names mapped to found paths
      #   @raise [Sevgi::ArgumentError] when any requested file is missing
      def existing_map!(...)
        found = F.existing_map(...)
        missings = found.select { |_, match| match.nil? }.keys

        ArgumentError.("No matching file(s) found: #{missings.join(", ")}") unless missings.empty?

        found
      end

      # Writes content to a file when it changed, or prints to stdout without a path.
      # @param content [String] output content
      # @param paths [Array<String>] path components for the output file
      # @yield optional normalization filter used for change detection
      # @yieldparam content [String] old or new content
      # @yieldreturn [String]
      # @return [String, nil] expanded file path when written, otherwise nil
      # @raise [Errno::EACCES] when the file cannot be read or written
      # @raise [Errno::ENOENT] when the parent directory does not exist
      def out(content, *paths, &filter)
        if paths.empty?
          ::Kernel.puts(content)
        else
          file = ::File.expand_path(::File.join(*paths))
          output = "#{content.chomp}\n"

          return unless changed?(file, output, &filter)

          file.tap { ::File.write(file, output) }
        end
      end

      # Adds a default extension when a path has no extension.
      # @param file [String] file path
      # @param default_extension [String] extension to append without a leading dot
      # @return [String] qualified file path
      def qualify(file, default_extension)
        return file unless ::File.extname(file).empty?

        "#{file}.#{default_extension}"
      end

      # Replaces or removes the extension on a path.
      # @param ext [String, nil] replacement extension, without or with a leading dot
      # @param paths [Array<String>] path components
      # @return [String] path with the replacement extension
      def subext(ext, *paths)
        path = ::File.join(*paths)

        return path if %w[. ..].include?(path)
        return path unless ext

        ext = ".#{ext}" unless ext.empty? || ext.start_with?(".")

        Pathname.new(path).sub_ext(ext).to_s
      end

      # Creates a file and any missing parent directories.
      # @param paths [Array<String>] path components for the file
      # @return [String] touched file path
      # @raise [Errno::EACCES] when the file or parent directory cannot be created
      def touch(*paths)
        ::File.join(*paths).tap do |path|
          ::FileUtils.mkdir_p(::File.dirname(path))
          ::FileUtils.touch(path)
        end
      end
    end

    extend File
  end
end
