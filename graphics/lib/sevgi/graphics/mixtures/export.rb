# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for native SVG export formats.
      module Export
        # Exports the document as PDF.
        # Relative paths are expanded, missing parent directories are created after export validation, and an existing
        # file is replaced. An existing directory target uses the caller-derived default PDF name.
        # @param path [String, #to_path, nil] output path or existing directory
        # @param kwargs [Hash] export options
        # @option kwargs [String, #to_path, nil] :default caller-derived output name used when path is nil or a directory
        # @yield [svg] transforms SVG source before rendering
        # @yieldparam svg [String] rendered SVG source
        # @yieldreturn [String] transformed SVG source
        # @return [String] expanded output path
        # @raise [Sevgi::ArgumentError] when a selected path/default is blank or invalid
        # @raise [Sevgi::MissingComponentError] when sevgi/sundries is unavailable
        # @raise [Sevgi::MissingComponentError] when native export gems are unavailable
        # @raise [Sevgi::Sundries::Export::ExportError] when native export fails
        # @raise [SystemCallError] when the output directory or file cannot be created or written
        def PDF(path = nil, **kwargs, &block)
          begin
            require "sevgi/sundries"

          rescue ::LoadError => e
            raise unless e.path == "sevgi/sundries"

            MissingComponentError.("sevgi/sundries")
          end

          Export(path, **kwargs, format: :pdf, &block)
        end

        # Exports the document as PNG.
        # Relative paths are expanded, missing parent directories are created after export validation, and an existing
        # file is replaced. An existing directory target uses the caller-derived default PNG name.
        # @param path [String, #to_path, nil] output path or existing directory
        # @param kwargs [Hash] export options
        # @option kwargs [String, #to_path, nil] :default caller-derived output name used when path is nil or a directory
        # @yield [svg] transforms SVG source before rendering
        # @yieldparam svg [String] rendered SVG source
        # @yieldreturn [String] transformed SVG source
        # @return [String] expanded output path
        # @raise [Sevgi::ArgumentError] when a selected path/default is blank or invalid
        # @raise [Sevgi::MissingComponentError] when sevgi/sundries is unavailable
        # @raise [Sevgi::MissingComponentError] when native export gems are unavailable
        # @raise [Sevgi::Sundries::Export::ExportError] when native export fails
        # @raise [SystemCallError] when the output directory or file cannot be created or written
        def PNG(path = nil, **kwargs, &block)
          begin
            require "sevgi/sundries"

          rescue ::LoadError => e
            raise unless e.path == "sevgi/sundries"

            MissingComponentError.("sevgi/sundries")
          end

          Export(path, **kwargs, format: :png, &block)
        end

        private

        def Export(path = nil, default: nil, **kwargs, &block)
          if default.nil?
            extension = kwargs[:format] ? ".#{kwargs[:format]}" : ".pdf"
            default = F.subext(extension, caller_locations(2..2).first.path)
          end

          path = Path.resolve(path, default:, context: "Export")

          Sundries::Export.(call, path, **kwargs, &block)
        end
      end
    end
  end
end
