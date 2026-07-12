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
    #
    # @example Export SVG source to a sized PNG
    #   svg = Sevgi::Graphics.SVG(:minimal) { circle(cx: 5, cy: 5, r: 4) }.Render
    #   Sevgi::Sundries::Export.call(svg, "drawing.png", width: 320)
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
      #   Relative paths are expanded, missing parent directories are created after all render inputs validate, and an
      #   existing output file is replaced. Directory paths are not expanded to a default file name.
      #   @param output [String, #to_path] output file path
      #   @param format [Symbol, String, nil] explicit output format, or nil to infer from output extension
      #   @param width [Numeric, nil] target width in output pixels for PNG, or CSS pixels before PDF point conversion
      #   @param height [Numeric, nil] target height in output pixels for PNG, or CSS pixels before PDF point conversion
      #   @param dpi [Numeric] finite positive CSS pixel density; omission uses {DEFAULT_DPI}, but explicit nil is invalid
      #   @param css [String, nil] CSS inserted before the closing svg tag before rendering
      #   @yield [svg] optional source transformation applied before rendering
      #   @yieldparam svg [String] SVG source after optional CSS injection
      #   @yieldreturn [String] SVG source to render
      #   @return [String] expanded output path
      #   @raise [Sevgi::ArgumentError] when SVG content is not a string or output is blank, invalid, or a directory
      #   @raise [Sevgi::MissingComponentError] when cairo, hexapdf, or rsvg2 is unavailable
      #   @raise [Sevgi::Sundries::Export::ExportError] when format, CSS insertion, SVG parsing, SVG dimensions, or
      #     render dimensions are invalid
      #   @raise [SystemCallError] when the output directory or file cannot be created or written
      def call(*args, **kwargs, &block) = native!.call(*args, **kwargs, &block)

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
        output = svg.sub("</svg>", "<style>#{css}</style></svg>")
        ExportError.("Cannot insert CSS: closing svg tag not found") if output == svg

        output
      end

      def normalize_format(format)
        unless format.is_a?(::String) || format.is_a?(::Symbol)
          ExportError.("Export format must be a String or Symbol: #{format.inspect}")
        end

        format.to_sym
      end

      private :format_for, :normalize_format, :styled

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
