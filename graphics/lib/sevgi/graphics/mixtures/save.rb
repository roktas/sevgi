# frozen_string_literal: true

require "fileutils"

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for writing rendered SVG output.
      module Save
        # Default SVG extension.
        EXT = ".svg"

        # Writes rendered SVG to standard output.
        # @param kwargs [Hash] render options
        # @yield [content] optionally transforms rendered content before output
        # @yieldparam content [String] rendered SVG source
        # @yieldreturn [String] transformed SVG source
        # @return [Object] F.out return value
        def Out(**kwargs, &filter)
          F.out(self.(**kwargs), &filter)
        end

        # Saves rendered SVG to a path derived from the caller by default.
        # @param path [String, nil] output path or directory
        # @param default [String, nil] default output path
        # @param backup_suffix [String, nil] suffix used for an existing-file backup
        # @yield [content] optionally transforms rendered content before output
        # @yieldparam content [String] rendered SVG source
        # @yieldreturn [String] transformed SVG source
        # @return [Object] F.out return value
        def Save(path = nil, default: nil, backup_suffix: nil, &filter)
          default ||= F.subext(EXT, caller_locations(1..1).first.path)

          if path
            ::File.directory?(path) ? ::File.join(path, ::File.basename(default)) : path
          else
            default
          end => path

          ::FileUtils.mkdir_p(::File.dirname(path))
          if backup_suffix && !backup_suffix.empty? && ::File.exist?(path)
            ::FileUtils.cp(path, "#{path}#{backup_suffix}")
          end

          Write(path, &filter)
        end

        # Writes rendered SVG to a path.
        # @param path [String] output path
        # @param kwargs [Hash] render options
        # @yield [content] optionally transforms rendered content before output
        # @yieldparam content [String] rendered SVG source
        # @yieldreturn [String] transformed SVG source
        # @return [Object] F.out return value
        def Write(path, **kwargs, &filter)
          F.out(self.(**kwargs), path, &filter)
        end
      end
    end
  end
end
