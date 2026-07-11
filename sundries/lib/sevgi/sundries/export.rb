# frozen_string_literal: true

require "sevgi/function"

require_relative "export/system"

module Sevgi
  module Sundries
    # Exports SVG content and post-processes PDF output.
    #
    # Native PDF/PNG rendering is loaded lazily so installing `sevgi-sundries` for SVG-only helpers does not require the
    # Cairo, RSVG, or HexaPDF gems. Native export entrypoints raise {Sevgi::MissingComponentError} when those optional
    # gems are unavailable.
    module Export
      # Supported export format names mapped to file extensions.
      AVAILABLE = (EXTENSIONS = {
        ".pdf" => :pdf,
        ".png" => :png
      }.freeze)
        .invert
        .freeze

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

      # @overload call(svg, output, format: nil, width: nil, height: nil, dpi: DEFAULT_DPI, css: nil)
      #   Exports SVG source to a PDF or PNG file using the optional native export gems.
      #   @param svg [String] SVG source content
      #   @param output [String, #to_s] output file path
      #   @param format [Symbol, String, nil] explicit output format, or nil to infer from output extension
      #   @param width [Numeric, nil] target width in output pixels for PNG, or CSS pixels before PDF point conversion
      #   @param height [Numeric, nil] target height in output pixels for PNG, or CSS pixels before PDF point conversion
      #   @param dpi [Numeric] CSS pixel density used for absolute SVG units and PDF point conversion
      #   @param css [String, nil] CSS inserted before the closing svg tag before rendering
      #   @yield [svg] optional source transformation applied before rendering
      #   @yieldparam svg [String] SVG source after optional CSS injection
      #   @yieldreturn [String] SVG source to render
      #   @return [Object] the original output argument
      #   @raise [Sevgi::ArgumentError] when SVG content is not a string or output is blank
      #   @raise [Sevgi::MissingComponentError] when cairo, hexapdf, or rsvg2 is unavailable
      #   @raise [Sevgi::Sundries::Export::ExportError] when format, SVG parsing, SVG dimensions, or render dimensions
      #     are invalid
      def call(*args, **kwargs, &block) = native!.call(*args, **kwargs, &block)

      # Resolves the export format from an explicit value or output extension.
      # @param format [Symbol, String, nil] explicit format
      # @param output [String, #to_s] output path
      # @return [Symbol] resolved format
      # @raise [Sevgi::Sundries::Export::ExportError] when the explicit format or output extension is unsupported
      def format_for!(format, output)
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

      # Inserts CSS before the closing svg tag.
      # @param svg [String] SVG source content
      # @param css [String] CSS source content
      # @return [String] SVG source with an added style element when a closing svg tag is present
      # @raise [NoMethodError] when SVG content does not support string substitution
      def inject(svg, css) = svg.sub("</svg>", "<style>#{css}</style></svg>")

      def normalize_format(format)
        unless format.is_a?(::String) || format.is_a?(::Symbol)
          ExportError.("Export format must be a String or Symbol: #{format.inspect}")
        end

        format.to_sym
      end

      private :normalize_format

      # Replaces exact placeholder text objects in PDF streams.
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
