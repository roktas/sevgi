# frozen_string_literal: true

require "cairo"
require "fileutils"
require "hexapdf"
require "rsvg2"
require "tempfile"

module Sevgi
  module Sundries
    # Exports SVG content and post-processes PDF output.
    module Export
      # Raised when SVG export or PDF post-processing cannot be completed.
      ExportError = Class.new(Error)

      # Default SVG CSS pixel density.
      DEFAULT_DPI = 96.0

      # Exports SVG source to a PDF or PNG file using librsvg and Cairo.
      # @param svg [String] SVG source content
      # @param output [String, #to_s] output file path
      # @param format [Symbol, String, nil] explicit output format, or nil to infer from output extension
      # @param width [Numeric, nil] target width in output pixels for PNG, or CSS pixels before PDF point conversion
      # @param height [Numeric, nil] target height in output pixels for PNG, or CSS pixels before PDF point conversion
      # @param dpi [Numeric] CSS pixel density used for absolute SVG units and PDF point conversion
      # @param css [String, nil] CSS inserted before the closing svg tag before rendering
      # @yield [svg] optional source transformation applied before rendering
      # @yieldparam svg [String] SVG source after optional CSS injection
      # @yieldreturn [String] SVG source to render
      # @return [Object] the original output argument
      # @raise [Sevgi::ArgumentError] when SVG content is not a string or output is blank
      # @raise [Sevgi::Sundries::Export::ExportError] when format, SVG parsing, SVG dimensions, or render dimensions are invalid
      def self.call(svg, output, format: nil, width: nil, height: nil, dpi: DEFAULT_DPI, css: nil, &block)
        ArgumentError.("SVG content must be a String") unless svg.is_a?(String)
        ArgumentError.("Export output must be provided") if output.nil? || output.to_s.strip.empty?

        svg = inject(svg, css) if css && !css.strip.empty?
        svg = block.call(svg) if block
        ArgumentError.("SVG content must be a String") unless svg.is_a?(String)

        format = format_for!(format, output)
        renderer = Renderer.method(format)

        begin
          handle = Rsvg::Handle.new_from_data(svg)

          iw, ih = intrinsic_size(handle)
          ExportError.("Invalid SVG dimensions") if iw <= 0 || ih <= 0

          scale = dpi / DEFAULT_DPI

          iw *= scale
          ih *= scale

          tw, th = target_size(iw, ih, width, height)
          ExportError.("Invalid export dimensions") unless target_size?(format, tw, th)

          renderer.call(
            handle: handle,
            output: output.to_s,
            iw: iw,
            ih: ih,
            tw: tw,
            th: th,
            dpi: dpi
          )
        rescue Rsvg::Error, Cairo::Error => e
          ExportError.("Render error: #{e.message}")
        end

        output
      end

      # Supported export format names mapped to file extensions.
      AVAILABLE = (EXTENSIONS = {
        ".pdf" => :pdf,
        ".png" => :png
      }.freeze)
        .invert
        .freeze

      # Resolves the export format from an explicit value or output extension.
      # @param format [Symbol, String, nil] explicit format
      # @param output [String, #to_s] output path
      # @return [Symbol] resolved format
      # @raise [Sevgi::Sundries::Export::ExportError] when the explicit format or output extension is unsupported
      def format_for!(format, output)
        if format
          format = format.to_sym
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
      def inject(svg, css) = svg.sub("</svg>", "<style>#{css}</style></svg>")

      # Replaces a placeholder text object in a PDF stream.
      # @param infile [String] source PDF file path
      # @param outfile [String] destination PDF file path
      # @param stamp [String] replacement text
      # @param placeholder [String] placeholder text to replace
      # @return [Boolean] true when a matching placeholder was replaced
      # @raise [Sevgi::Sundries::Export::ExportError] when the PDF files cannot be read, written, or stamped
      def stamp(infile, outfile, stamp:, placeholder:)
        doc = HexaPDF::Document.open(infile)
        stamped = false

        doc.pages.each do |page|
          Array(page[:Contents]).each do |ref|
            obj = doc.object(ref)
            next unless obj.respond_to?(:stream)

            data = obj.stream
            next unless data.include?("(#{placeholder})")

            data = data.gsub(
              %r{1 1 1 rg (BT\s+.*?/\S+ \d+ Tf\s+)\(#{Regexp.escape(placeholder)}\)Tj}m,
              "0.101961 0.101961 0.101961 rg \\1(#{stamp})Tj"
            )

            obj.stream = data
            obj.set_filter(:FlateDecode)
            stamped = true
          end
        end

        doc.write(outfile, optimize: true) if stamped
        stamped
      rescue HexaPDF::Error, ::SystemCallError => e
        ExportError.("PDF stamp error: #{e.message}")
      end

      # Replaces a placeholder text object inside a PDF file in place.
      # @param infile [String] PDF file path to modify
      # @param stamp [String] replacement text
      # @param placeholder [String] placeholder text to replace
      # @return [Boolean] true when a matching placeholder was replaced
      # @raise [Sevgi::Sundries::Export::ExportError] when the PDF file cannot be read, written, stamped, or replaced
      def stamp!(infile, stamp:, placeholder:)
        temp = Tempfile.new(%w[stamp .pdf], File.dirname(infile))
        stamped = stamp(infile, temp.path, stamp:, placeholder:)
        if stamped
          if File.exist?(temp.path) && File.empty?(temp.path)
            warn("Skipping 0 byte file which was produced during stamping")
          else
            FileUtils.mv(temp.path, infile)
          end
        end

        stamped
      rescue ::SystemCallError => e
        ExportError.("PDF stamp error: #{e.message}")
      ensure
        temp&.close!
      end

      class << self
        private

        def intrinsic_size(handle)
          if handle.respond_to?(:intrinsic_dimensions)
            has_width, width, has_height, height, has_viewbox, viewbox = handle.intrinsic_dimensions

            if has_width && has_height
              width = to_px(width)
              height = to_px(height)
              return [width, height] if width.positive? && height.positive?
            end

            if handle.respond_to?(:intrinsic_size_in_pixels)
              has_size, width, height = handle.intrinsic_size_in_pixels
              return [width.to_f, height.to_f] if has_size && width.to_f.positive? && height.to_f.positive?
            end

            if has_viewbox && viewbox.width.to_f.positive? && viewbox.height.to_f.positive?
              return [viewbox.width.to_f, viewbox.height.to_f]
            end
          end

          d = handle.dimensions
          [d.width.to_f, d.height.to_f]
        end

        def to_px(dimension)
          value = dimension.length.to_f

          case dimension.unit
          when Rsvg::Unit::PX
            value
          when Rsvg::Unit::IN
            value * DEFAULT_DPI
          when Rsvg::Unit::CM
            value * DEFAULT_DPI / 2.54
          when Rsvg::Unit::MM
            value * DEFAULT_DPI / 25.4
          when Rsvg::Unit::PT
            value * DEFAULT_DPI / 72.0
          when Rsvg::Unit::PC
            value * DEFAULT_DPI / 6.0
          else
            0.0
          end
        end

        def target_size(iw, ih, width, height)
          if width && height
            s = [width.to_f / iw, height.to_f / ih].min
            [(iw * s), (ih * s)]
          elsif width
            s = width.to_f / iw
            [(iw * s), (ih * s)]
          elsif height
            s = height.to_f / ih
            [(iw * s), (ih * s)]
          else
            [iw, ih]
          end
        end

        def target_size?(format, width, height)
          return false if width <= 0 || height <= 0
          return false unless width.finite? && height.finite?
          return true unless format == :png

          width.round.positive? && height.round.positive?
        end
      end

      # Low-level format renderers used by {Export.call}.
      # @api private
      module Renderer
        extend self

        # Returns a renderer method for a format.
        # @param format [Symbol, String, nil] format name
        # @return [Method, nil]
        def [](format)
          case format&.to_sym
          when :png
            method(:png)
          when :pdf
            method(:pdf)
          end
        end

        # Renders SVG data to a PDF surface.
        # @param handle [Rsvg::Handle] parsed SVG handle
        # @param output [String] output file path
        # @param tw [Numeric] target width in CSS pixels
        # @param th [Numeric] target height in CSS pixels
        # @param dpi [Numeric] CSS pixel density
        # @return [void]
        # @raise [Cairo::Error] when Cairo cannot write the PDF surface
        # @raise [Rsvg::Error] when librsvg cannot render the document
        def pdf(handle:, output:, tw:, th:, dpi:, **)
          pw, ph = tw * (72.0 / dpi), th * (72.0 / dpi)
          surface = Cairo::PDFSurface.new(output, pw, ph)
          context = Cairo::Context.new(surface)
          context.scale(pw / tw, ph / th)
          handle.render_document(context, viewport(tw, th))
          context.show_page
          surface.finish
        end

        # Renders SVG data to a PNG image.
        # @param handle [Rsvg::Handle] parsed SVG handle
        # @param output [String] output file path
        # @param tw [Numeric] target width in CSS pixels
        # @param th [Numeric] target height in CSS pixels
        # @return [void]
        # @raise [Cairo::Error] when Cairo cannot write the PNG surface
        # @raise [Rsvg::Error] when librsvg cannot render the document
        def png(handle:, output:, tw:, th:, **)
          surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, tw.round, th.round)
          context = Cairo::Context.new(surface)
          handle.render_document(context, viewport(tw, th))
          surface.write_to_png(output)
        end

        private

        def viewport(width, height)
          Rsvg::Rectangle.new.tap do |rectangle|
            rectangle.x = 0
            rectangle.y = 0
            rectangle.width = width
            rectangle.height = height
          end
        end
      end
    end
  end
end
