# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for native SVG export formats.
      # Export CSS is a late adjustment after document checks. Its supported XML endings and cascade limitations are
      # documented in {Sevgi::Sundries::Export}. The source callback receives SVG after CSS insertion.
      module Export
        # Validates export options and executes export after loading optional dependencies.
        # @api private
        module Runner
          PDF_KEYS = %i[css declaration default dpi fallback height preview width].freeze
          PNG_KEYS = %i[css default dpi height width].freeze
          KEYS = {pdf: PDF_KEYS, png: PNG_KEYS}.freeze

          # Validates options, ensures optional sundries loading, and invokes the exporter.
          # @param element [Sevgi::Graphics::Element] document or element to export
          # @param path [String, #to_path, nil] output path or existing directory
          # @param format [Symbol] target export format (`:pdf` or `:png`)
          # @param caller_path [String, nil] caller source path for default naming
          # @param kwargs [Hash] export options
          # @yield [svg] optional SVG post-processor
          # @return [String] expanded output path
          # @raise [Sevgi::ArgumentError] when an option or path is invalid
          # @raise [Sevgi::MissingComponentError] when sevgi/sundries is unavailable
          def self.call(element, path, format:, caller_path:, **kwargs, &block)
            validate_options!(kwargs, format)
            load_sundries!
            kwargs = with_declaration(element, format, kwargs)
            output = resolve_output(path, format, caller_path, kwargs)

            Sundries::Export.(element.call, output, **kwargs, format:, &block)
          end

          class << self
            private

            def validate_options!(kwargs, format)
              unknown = kwargs.keys - KEYS.fetch(format)
              ArgumentError.("Unknown export option: #{unknown.first}") unless unknown.empty?
            end

            def with_declaration(element, format, kwargs)
              return kwargs unless format == :pdf && !kwargs.key?(:declaration)
              return kwargs unless element.Root?() && element.respond_to?(:Imprint)

              imprint = element.Imprint()
              imprint.nil? ? kwargs : kwargs.merge(declaration: imprint)
            end

            def resolve_output(path, format, caller_path, kwargs)
              default = kwargs.delete(:default)
              default = F.subext(".#{format}", caller_path) if default.nil?
              F.output_path(path, default:, context: "Export")
            end

            def load_sundries!
              require "sevgi/sundries"

            rescue ::LoadError => e
              raise unless e.path == "sevgi/sundries"

              MissingComponentError.("sevgi/sundries")
            end
          end
        end

        private_constant :Runner

        # Exports the document as PDF.
        # Relative paths are expanded, missing parent directories are created after export validation, and an existing
        # file is replaced. An existing directory target uses the caller-derived default PDF name.
        # @param path [String, #to_path, nil] output path or existing directory
        # @param kwargs [Hash] export options
        # @option kwargs [String, #to_path, nil] :default caller-derived output name used when path is nil or a directory
        # @option kwargs [Numeric, nil] :width finite positive target width in CSS pixels
        # @option kwargs [Numeric, nil] :height finite positive target height in CSS pixels
        # @option kwargs [Numeric] :dpi (96.0) finite positive CSS pixel density
        # @option kwargs [String, nil] :css CSS inserted before rendering
        # @option kwargs [Hash, nil] :declaration (document Imprint) producer declaration; nil omits the document declaration
        # @option kwargs [String, nil] :preview separate PNG thumbnail bytes; selects Mainz even without a declaration
        # @option kwargs [Boolean] :fallback (true) warn and use ordinary PDF after preparation failure
        # @yield [svg] transforms SVG source before rendering
        # @yieldparam svg [String] rendered SVG source
        # @yieldreturn [String] transformed SVG source
        # @return [String] expanded output path
        # @raise [Sevgi::ArgumentError] when a path, default, option name, CSS value, or transformed SVG is invalid
        # @raise [Sevgi::ValidationError] when validation is enabled and the document violates the SVG standard
        # @raise [Sevgi::Graphics::LintError] when linting is enabled and the document has structural conflicts
        # @raise [Sevgi::MissingComponentError] when sevgi/sundries is unavailable
        # @raise [Sevgi::MissingComponentError] when native export gems are unavailable
        # @raise [Sevgi::Sundries::Export::ExportError] when native export fails
        # @raise [Sevgi::Sundries::Imprint::Error] when required preparation cannot complete
        # @raise [SystemCallError] when the output directory or file cannot be created or written
        def PDF(path = nil, **kwargs, &block)
          Runner.(self, path, caller_path: caller_locations(1, 1).first&.path, **kwargs, format: :pdf, &block)
        end

        # Exports the document as PNG.
        # Relative paths are expanded, missing parent directories are created after export validation, and an existing
        # file is replaced. An existing directory target uses the caller-derived default PNG name.
        # @param path [String, #to_path, nil] output path or existing directory
        # @param kwargs [Hash] export options
        # @option kwargs [String, #to_path, nil] :default caller-derived output name used when path is nil or a directory
        # @option kwargs [Numeric, nil] :width finite positive target width in output pixels
        # @option kwargs [Numeric, nil] :height finite positive target height in output pixels
        # @option kwargs [Numeric] :dpi (96.0) finite positive CSS pixel density
        # @option kwargs [String, nil] :css CSS inserted before rendering
        # @yield [svg] transforms SVG source before rendering
        # @yieldparam svg [String] rendered SVG source
        # @yieldreturn [String] transformed SVG source
        # @return [String] expanded output path
        # @raise [Sevgi::ArgumentError] when a path, default, option name, CSS value, or transformed SVG is invalid
        # @raise [Sevgi::ValidationError] when validation is enabled and the document violates the SVG standard
        # @raise [Sevgi::Graphics::LintError] when linting is enabled and the document has structural conflicts
        # @raise [Sevgi::MissingComponentError] when sevgi/sundries is unavailable
        # @raise [Sevgi::MissingComponentError] when native export gems are unavailable
        # @raise [Sevgi::Sundries::Export::ExportError] when native export fails
        # @raise [SystemCallError] when the output directory or file cannot be created or written
        def PNG(path = nil, **kwargs, &block)
          Runner.(self, path, caller_path: caller_locations(1, 1).first&.path, **kwargs, format: :png, &block)
        end
      end
    end
  end
end
