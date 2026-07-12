# frozen_string_literal: true

require "fileutils"

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for writing rendered SVG output.
      module Save
        # Default SVG extension.
        EXT = ".svg"

        # Change-aware file writer with optional backup support.
        # @api private
        class Writer
          # Writes content when it differs from the destination.
          # @param path [String, #to_path] output path
          # @param content [String] rendered content
          # @param backup_suffix [String, nil] suffix used for an existing-file backup
          # @yield [content] optionally normalizes old and new content for change detection
          # @yieldparam content [String] old or new content
          # @yieldreturn [String] normalized content
          # @return [String, nil] expanded path when written, otherwise nil
          # @raise [SystemCallError] when the destination or backup cannot be created, read, or written
          def self.call(path, content, backup_suffix: nil, &filter)
            path = ::File.expand_path(path)
            output = "#{content.chomp}\n"

            return unless F.changed?(path, output, &filter)

            ::FileUtils.mkdir_p(::File.dirname(path))
            if backup_suffix && !backup_suffix.empty? && ::File.exist?(path)
              ::FileUtils.cp(path, "#{path}#{backup_suffix}")
            end

            path.tap { ::File.write(path, output) }
          end
        end

        private_constant :Writer

        # Writes rendered SVG to standard output.
        # @param kwargs [Hash] render options
        # @return [nil]
        # @raise [Sevgi::ArgumentError] when rendering fails
        def Out(**kwargs)
          F.out(self.(**kwargs))
        end

        # Saves rendered SVG when its content differs from the destination.
        # Relative destinations are expanded before being returned. When a non-empty backup suffix is given, an
        # existing destination is copied immediately before replacement; unchanged saves leave both files untouched.
        # Missing parent directories are created. An existing directory target uses the default file name.
        # @param path [String, #to_path, nil] output path or existing directory
        # @param default [String, #to_path, nil] default output path
        # @param backup_suffix [String, nil] suffix used for an existing-file backup
        # @param kwargs [Hash] render options
        # @yield [content] optionally normalizes old and new content for change detection
        # @yieldparam content [String] old or new SVG source
        # @yieldreturn [String] normalized SVG source
        # @return [String, nil] expanded path when written, or nil when unchanged
        # @raise [Sevgi::ArgumentError] when rendering fails
        # @raise [SystemCallError] when the destination or backup cannot be created, read, or written
        def Save(path = nil, default: nil, backup_suffix: nil, **kwargs, &filter)
          default ||= F.subext(EXT, caller_locations(1..1).first.path)

          if path
            ::File.directory?(path) ? ::File.join(path, ::File.basename(default)) : path
          else
            default
          end => path

          Writer.(path, self.(**kwargs), backup_suffix:, &filter)
        end

        # Writes rendered SVG to a path.
        # Missing parent directories are created. Unlike {#Save}, a directory is not treated as a request for a default
        # file name.
        # @param path [String, #to_path] output file path
        # @param kwargs [Hash] render options
        # @yield [content] optionally normalizes old and new content for change detection
        # @yieldparam content [String] old or new SVG source
        # @yieldreturn [String] normalized SVG source
        # @return [String, nil] expanded path when written, or nil when unchanged
        # @raise [Sevgi::ArgumentError] when rendering fails
        # @raise [SystemCallError] when the destination cannot be read or written
        def Write(path, **kwargs, &filter)
          Writer.(path, self.(**kwargs), &filter)
        end
      end
    end
  end
end
