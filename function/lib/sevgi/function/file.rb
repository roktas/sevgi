# frozen_string_literal: true

require "fileutils"

module Sevgi
  module Function
    # File-system methods promoted to {Sevgi::F}. This module organizes the facade implementation. It is not a consumer
    # mixin contract.
    module File
      # Checks whether a file differs from the supplied content.
      # @param file [String] file path to compare
      # @param content [String] proposed file content
      # @yield optional normalization filter applied to both old and new content
      # @yieldparam content [String] content to normalize
      # @yieldreturn [String]
      # @return [Boolean] true when the file is missing or content differs
      # @raise [SystemCallError] when the file cannot be inspected or read
      def changed?(file, content, &filter)
        return true unless ::File.exist?(file)

        old_content = ::File.read(file)
        old_content, content = [old_content, content].map(&filter) if filter

        old_content != content
      end

      # Finds an existing file by exact path or by trying default extensions.
      # @param file [String] file path or extensionless basename
      # @param extensions [Array<String>] extensions to try when file has no extension
      # @return [String, nil] matching file path, or nil when no file is found
      def existing(file, extensions)
        return file if ::File.file?(file)
        return nil unless ::File.extname(file).empty?
        return nil if extensions.empty?

        extensions.map { |ext| "#{file}.#{ext}" }.detect { |file| ::File.file?(file) }
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
      # @raise [SystemCallError] when the destination cannot be inspected, read, or written
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

      # Resolves an output path, using the default when value is nil or an existing directory.
      # The default is validated only when used. This method does not create files or directories.
      # @param value [String, #to_path, nil] explicit output path or directory
      # @param default [String, #to_path] default output path; its basename is used for a directory target
      # @param context [String] public operation named in errors
      # @return [String] expanded output path
      # @raise [Sevgi::ArgumentError] when a selected path/default is blank, invalid, or cannot be converted
      def output_path(value, default:, context: "Output")
        return path(default, context: "#{context} default") if value.nil?

        output = path(value, context: "#{context} path")
        return output unless ::File.directory?(output)

        default = path(default, context: "#{context} default")
        ::File.join(output, ::File.basename(default))
      end

      # Converts a non-blank path to an expanded String without requiring it to exist.
      # @param value [String, #to_path] raw path value
      # @param context [String] error-message subject
      # @return [String] expanded path
      # @raise [Sevgi::ArgumentError] when value is blank, has an invalid type, or path conversion fails
      def path(value, context: "Path")
        path = value.respond_to?(:to_path) ? value.to_path : value
        ArgumentError.("#{context} must be a String or path-like object") unless path.is_a?(::String)
        ArgumentError.("#{context} must be provided") if path.strip.empty?

        ::File.expand_path(path)
      rescue ::Sevgi::ArgumentError
        raise
      rescue ::StandardError => e
        ArgumentError.("#{context} must be a String or path-like object: #{e.message}")
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
      # @raise [SystemCallError] when the file or parent directory cannot be created
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
