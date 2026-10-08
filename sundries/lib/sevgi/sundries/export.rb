# frozen_string_literal: true

require "sevgi/function"

require_relative "export/system"
require_relative "export/input"
require_relative "mainz"

module Sevgi
  module Sundries
    # Exports SVG source to PNG or PDF and post-processes PDF output.
    #
    # Native PDF/PNG rendering is loaded lazily so installing `sevgi-sundries` for SVG-only helpers does not require the
    # Cairo, RSVG, or HexaPDF gems. Native export entrypoints raise {Sevgi::MissingComponentError} when those optional
    # gems are unavailable. Omit `format:` to infer it from the output suffix.
    # width and height are output dimensions rather than changes to the SVG
    # viewBox. The return value is the expanded path that was written.
    # Export-only CSS is a last-minute adjustment, not a replacement for document styles or validation. Insertion
    # requires well-formed SVG ending in an unprefixed `</svg>` followed only by XML whitespace. Self-closing roots,
    # prefixed roots, and trailing comments are unsupported with CSS. CSS is XML-escaped but not parsed or validated.
    # The source callback runs after insertion and before ordinary or prepared conversion.
    #
    # @example Export SVG source to a sized PNG
    #   svg = Sevgi::Graphics.SVG(width: 10, height: 10) { circle cx: 5, cy: 5, r: 4 }.Render
    #   Sevgi::Sundries::Export.call(svg, "drawing.png", width: 320)
    # @example Infer PDF output and inject export-only CSS
    #   svg = Sevgi::Graphics.SVG(width: 10, height: 10) { circle class: "accent", cx: 5, cy: 5, r: 4 }.Render
    #   Sevgi::Sundries::Export.call(svg, "drawing.pdf", css: ".accent { fill: tomato; }")
    # @see https://sevgi.roktas.dev/output/#export Export guide
    module Export
      # File extensions mapped to export format names.
      # @api private
      EXTENSIONS = {
        ".pdf" => :pdf,
        ".png" => :png
      }.freeze
      private_constant :EXTENSIONS

      # Supported export format names mapped to file extensions.
      AVAILABLE = EXTENSIONS.invert.freeze

      # Default SVG CSS pixel density.
      DEFAULT_DPI = 96.0

      # Raised when SVG export or PDF post-processing cannot be completed.
      ExportError = Class.new(Error)

      NATIVE_COMPONENTS = %w[
        cairo
        hexapdf
        rsvg2
      ].freeze

      private_constant :NATIVE_COMPONENTS

      # rubocop:disable Metrics/ParameterLists

      # Exports SVG source through ordinary rendering or optional Mainz preparation.
      # Style selects Mainz automatically for PDF output. Unstyled documents use ordinary export.
      # Fallback warns and uses ordinary PDF export after a preparation failure.
      # CSS and the source callback run once before either backend receives the source.
      # @param svg [String] SVG source content
      # @param output [String, #to_path] output file path
      # @param format [Symbol, String, nil] explicit output format, or nil to infer from output extension
      # @param width [Numeric, nil] target width in output pixels for PNG, or CSS pixels before PDF point conversion
      # @param height [Numeric, nil] target height in output pixels for PNG, or CSS pixels before PDF point conversion
      # @param dpi [Numeric] finite positive CSS pixel density. Omission uses {DEFAULT_DPI}, but explicit nil is invalid
      # @param css [String, nil] CSS inserted before the closing svg tag before rendering
      # @param style [Hash, nil] optional JSON authoring declaration
      # @param fallback [Boolean] permit ordinary export after prepared export fails
      # @yield [svg] optional source transformation before rendering
      # @yieldparam svg [String] SVG source after optional CSS insertion
      # @yieldreturn [String] SVG source to render
      # @return [String] expanded output path
      # @raise [Sevgi::ArgumentError] when the source, path, declaration, or fallback value is invalid
      # @raise [Sevgi::MissingComponentError] when ordinary export requires unavailable native gems
      # @raise [Sevgi::Sundries::Export::ExportError] when format, dimensions, CSS insertion, or ordinary rendering fails
      # @raise [Sevgi::Sundries::Mainz::Error] when preparation fails and fallback is false
      # @raise [SystemCallError] when the output directory or file cannot be written
      def call(svg, output, format: nil, width: nil, height: nil, dpi: DEFAULT_DPI, css: nil,
        style: nil, fallback: true, &block)
        output = output_path(output)
        format = format_for(format, output)
        input = Input.new(svg, {width:, height:, dpi:, css:, style:, fallback:}, &block)
        return output if format == :pdf && prepared(input, output)
        native!
        render(input.svg, output, format:, **input.dimensions)
      end
      # rubocop:enable Metrics/ParameterLists

      def format_for(format, output)
        if format
          format = normalize_format(format)
          ExportError.("Unsupported export format: #{format}") unless AVAILABLE.key?(format)

          format
        else
          ext = File.extname(output.to_s).downcase
          ExportError.("Unrecognized file extension: #{ext}") unless EXTENSIONS.key?(ext)

          EXTENSIONS[ext]
        end
      end

      def styled(svg, css)
        ArgumentError.("Export CSS must be valid text") unless css.is_a?(::String) && css.valid_encoding?
        closing = %r{</svg>[ \t\r\n]*\z}
        ExportError.("Cannot insert CSS: expected final </svg> root closing tag") unless closing.match?(svg)

        text = css.gsub(/[&<>]/, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        svg.sub(closing) { |suffix| "<style>#{text}</style>#{suffix}" }
      end

      def normalize_format(format)
        unless format.is_a?(::String) || format.is_a?(::Symbol)
          ExportError.("Export format must be a String or Symbol: #{format.inspect}")
        end

        format.to_sym
      end

      private :format_for, :normalize_format, :styled

      # Replaces exact placeholder text objects in PDF streams.
      # The placeholder must be a PDF literal string inside a white text object that matches Sevgi's stamp pattern.
      # Replacement text is escaped as a PDF literal string. When no match exists, the method writes no output file.
      # @param infile [String] source PDF file path
      # @param outfile [String] destination PDF file path
      # @param stamp [String] replacement text
      # @param placeholder [String] placeholder text to replace
      # @return [Boolean] true when at least one matching placeholder was replaced
      # @raise [Sevgi::MissingComponentError] when native export gems are unavailable
      # @raise [Sevgi::Sundries::Export::ExportError] when the PDF cannot be read, rewritten, or stamped
      # @note Streams with unbalanced graphics-state or text-object operators are left unchanged.
      def stamp(infile, outfile, stamp:, placeholder:) = native!.stamp(infile, outfile, stamp:, placeholder:)

      # Replaces exact placeholder text objects inside a PDF file in place.
      # The input file changes only after at least one exact match produces a nonempty output file.
      # @param infile [String] PDF file path to modify
      # @param stamp [String] replacement text
      # @param placeholder [String] placeholder text to replace
      # @return [Boolean] true when at least one matching placeholder was replaced
      # @raise [Sevgi::MissingComponentError] when native export gems are unavailable
      # @raise [Sevgi::Sundries::Export::ExportError] when the PDF cannot be read, rewritten, stamped, or replaced
      # @note Streams with unbalanced graphics-state or text-object operators are left unchanged.
      def stamp!(infile, stamp:, placeholder:) = native!.stamp!(infile, stamp:, placeholder:)

      extend self

      class << self
        private

        def prepared(input, output)
          return false unless input.style
          Mainz.send(:write, input, output)
          true
        rescue Mainz::Error => e
          raise unless input.fallback
          warn("#{e.message}; exporting an ordinary PDF without editable styles")
          false
        end

        # Preserve the existing path and conversion-error contract.
        # rubocop:disable-next Metrics/AbcSize, Metrics/CyclomaticComplexity
        def output_path(output)
          ArgumentError.("Export output must be provided") if output.nil?
          path = output.respond_to?(:to_path) ? output.to_path : output
          ArgumentError.("Export output must be a String or path-like object") unless path.is_a?(::String)
          ArgumentError.("Export output must be provided") if path.strip.empty?
          path = ::File.expand_path(path)
          ArgumentError.("Export output must name a file") if ::File.directory?(path)
          path
        rescue ::StandardError => e
          raise if e.is_a?(::Sevgi::ArgumentError)
          ArgumentError.("Export output must be a String or path-like object: #{e.message}")
        end

        def native!
          require_relative "export/native"

          self
        rescue ::LoadError => e
          raise unless NATIVE_COMPONENTS.include?(e.path)

          MissingComponentError.(NATIVE_COMPONENTS.join(", "))
        end
      end
    end
  end
end
