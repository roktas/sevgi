# frozen_string_literal: true

require "cairo"
require "fileutils"
require "hexapdf"
require "rsvg2"
require "tempfile"

module Sevgi
  module Sundries
    module Export
      ExportError = Class.new(Error)

      DEFAULT_DPI = 96.0

      def self.call(svg, output, format: nil, width: nil, height: nil, dpi: DEFAULT_DPI, css: nil, &block)
        ArgumentError.("SVG content must be a String") unless svg.is_a?(String)
        ArgumentError.("Export output must be provided") if output.nil? || output.to_s.strip.empty?

        svg = inject(svg, css) if css && !css.strip.empty?
        svg = block.call(svg) if block

        renderer = Renderer.method(format_for!(format, output))
        handle   = Rsvg::Handle.new_from_data(svg)

        iw, ih = intrinsic_size(handle)
        ExportError.("Invalid SVG dimensions") if iw <= 0 || ih <= 0

        scale = dpi / DEFAULT_DPI

        iw *= scale
        ih *= scale

        tw, th = target_size(iw, ih, width, height)

        begin
          renderer.call(
            handle: handle,
            output: output.to_s,
            iw:     iw,
            ih:     ih,
            tw:     tw,
            th:     th,
            dpi:    dpi
          )
        rescue Rsvg::Error, Cairo::Error => e
          ExportError.("Render error: #{e.message}")
        end

        output
      end

      AVAILABLE = (EXTENSIONS = {
        ".pdf" => :pdf,
        ".png" => :png
      }.freeze).invert.freeze

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

      def inject(svg, css) = svg.sub("</svg>", "<style>#{css}</style></svg>")

      def stamp(infile, outfile, stamp:, placeholder:)
        doc     = HexaPDF::Document.open(infile)
        stamped = false

        doc.pages.each do |page|
          Array(page[:Contents]).each do |ref|
            obj = doc.object(ref)
            next unless obj.respond_to?(:stream)

            data = obj.stream
            next unless data.include?("(#{placeholder})")

            data = data.gsub(
              /1 1 1 rg (BT\s+.*?\/\S+ \d+ Tf\s+)\(#{Regexp.escape(placeholder)}\)Tj/m,
              "0.101961 0.101961 0.101961 rg \\1(#{stamp})Tj"
            )

            obj.stream = data
            obj.set_filter(:FlateDecode)
            stamped = true
          end
        end

        doc.write(outfile, optimize: true) if stamped
        stamped
      end

      def stamp!(infile, stamp:, placeholder:)
        temp    = Tempfile.new(%w[stamp .pdf], File.dirname(infile))
        stamped = stamp(infile, temp.path, stamp:, placeholder:)
        if stamped
          if File.exist?(temp.path) && File.zero?(temp.path)
            warn("Skipping 0 byte file which was produced during stamping")
          else
            FileUtils.mv(temp.path, infile)
          end
        end
        stamped
      ensure
        temp&.close!
      end

      class << self
        private

        def intrinsic_size(handle)
          if handle.respond_to?(:intrinsic_dimensions)
            has_width, width, has_height, height, has_viewbox, viewbox = handle.intrinsic_dimensions

            if has_width && has_height
              width  = to_px(width)
              height = to_px(height)
              return [ width, height ] if width > 0 && height > 0
            end

            if handle.respond_to?(:intrinsic_size_in_pixels)
              has_size, width, height = handle.intrinsic_size_in_pixels
              return [ width.to_f, height.to_f ] if has_size && width.to_f > 0 && height.to_f > 0
            end

            if has_viewbox && viewbox.width.to_f > 0 && viewbox.height.to_f > 0
              return [ viewbox.width.to_f, viewbox.height.to_f ]
            end
          end

          d = handle.dimensions
          [ d.width.to_f, d.height.to_f ]
        end

        def to_px(dimension)
          value = dimension.length.to_f

          case dimension.unit
          when Rsvg::Unit::PX then value
          when Rsvg::Unit::IN then value * DEFAULT_DPI
          when Rsvg::Unit::CM then value * DEFAULT_DPI / 2.54
          when Rsvg::Unit::MM then value * DEFAULT_DPI / 25.4
          when Rsvg::Unit::PT then value * DEFAULT_DPI / 72.0
          when Rsvg::Unit::PC then value * DEFAULT_DPI / 6.0
          else 0.0
          end
        end

        def target_size(iw, ih, width, height)
          if width && height
            s = [ width.to_f / iw, height.to_f / ih ].min
            [ (iw * s), (ih * s) ]
          elsif width
            s = width.to_f / iw
            [ (iw * s), (ih * s) ]
          elsif height
            s = height.to_f / ih
            [ (iw * s), (ih * s) ]
          else
            [ iw, ih ]
          end
        end
      end

      module Renderer
        extend self

        def [](format)
          case format&.to_sym
          when :png then method(:png)
          when :pdf then method(:pdf)
          else nil
          end
        end

        def pdf(handle:, output:, tw:, th:, dpi:, **)
          pw, ph  = tw * (72.0 / dpi), th * (72.0 / dpi)
          surface = Cairo::PDFSurface.new(output, pw, ph)
          context = Cairo::Context.new(surface)
          context.scale(pw / tw, ph / th)
          handle.render_document(context, viewport(tw, th))
          context.show_page
          surface.finish
        end

        def png(handle:, output:, tw:, th:, **)
          surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, tw.round, th.round)
          context = Cairo::Context.new(surface)
          handle.render_document(context, viewport(tw, th))
          surface.write_to_png(output)
        end

        private

          def viewport(width, height)
            Rsvg::Rectangle.new.tap do |rectangle|
              rectangle.x      = 0
              rectangle.y      = 0
              rectangle.width  = width
              rectangle.height = height
            end
          end
      end
    end
  end
end
