# frozen_string_literal: true

module Sevgi
  module Sundries
    module Export
      # Renders validated SVG content to PDF or PNG through librsvg and Cairo.
      # @api private
      module Render
        extend self

        UNIT_SCALES = {
          Rsvg::Unit::PX => 1.0,
          Rsvg::Unit::IN => DEFAULT_DPI,
          Rsvg::Unit::CM => DEFAULT_DPI / 2.54,
          Rsvg::Unit::MM => DEFAULT_DPI / 25.4,
          Rsvg::Unit::PT => DEFAULT_DPI / 72.0,
          Rsvg::Unit::PC => DEFAULT_DPI / 6.0
        }.freeze

        # Renders SVG content to an output file via atomic staging.
        # @param svg [String] SVG source content
        # @param output [String] destination file path
        # @param format [Symbol] export format (`:pdf` or `:png`)
        # @param dimensions [Hash] target width, height, and dpi options
        # @return [String] expanded destination file path
        # @raise [Sevgi::Sundries::Export::ExportError] when dimensions or rendering fail
        def call(svg, output, format:, dimensions:)
          handle = Rsvg::Handle.new_from_data(svg)
          tw, th = resolve_target_size(handle, format, dimensions)
          render_staged(handle, output, format:, size: [tw, th], dpi: dimensions.fetch(:dpi))
          output
        rescue Rsvg::Error, Cairo::Error => e
          ExportError.("Render error: #{e.message}")
        end

        private

        def resolve_target_size(handle, format, dimensions)
          iw, ih = scaled_intrinsic_size(handle, dimensions.fetch(:dpi))
          tw, th = target_size(iw, ih, dimensions[:width], dimensions[:height])
          ExportError.("Invalid export dimensions") unless target_size?(format, tw, th)
          [tw, th]
        end

        def render_staged(handle, output, format:, size:, dpi:)
          tw, th = size

          Staging.replace(output, prefix: ".sevgi-render-", filename: "output.#{format}") do |staged|
            dispatch_renderer(format, handle:, output: staged, size: [tw, th], dpi:)
            true
          end
        end

        def dispatch_renderer(format, handle:, output:, size:, dpi:)
          tw, th = size
          case format
          when :pdf
            Renderer.pdf(handle:, output:, tw:, th:, dpi:)
          when :png
            Renderer.png(handle:, output:, tw:, th:)
          end
        end

        def scaled_intrinsic_size(handle, dpi)
          iw, ih = intrinsic_size(handle)
          ExportError.("Invalid SVG dimensions") if iw <= 0 || ih <= 0

          scale = dpi / DEFAULT_DPI
          [iw * scale, ih * scale]
        end

        def intrinsic_size(handle)
          if handle.respond_to?(:intrinsic_dimensions)
            size = explicit_or_viewbox_size(handle)
            return size if size
          end

          dimensions = handle.dimensions
          [dimensions.width.to_f, dimensions.height.to_f]
        end

        def explicit_or_viewbox_size(handle)
          has_width, width, has_height, height, has_viewbox, viewbox = handle.intrinsic_dimensions
          if has_width && has_height
            px_width, px_height = to_px(width), to_px(height)
            return [px_width, px_height] if px_width.positive? && px_height.positive?
          end

          pixel_intrinsic_size(handle) || viewbox_size(has_viewbox, viewbox)
        end

        def pixel_intrinsic_size(handle)
          return unless handle.respond_to?(:intrinsic_size_in_pixels)

          has_size, width, height = handle.intrinsic_size_in_pixels
          [width.to_f, height.to_f] if has_size && width.to_f.positive? && height.to_f.positive?
        end

        def viewbox_size(has_viewbox, viewbox)
          return unless has_viewbox && viewbox.width.to_f.positive? && viewbox.height.to_f.positive?

          [viewbox.width.to_f, viewbox.height.to_f]
        end

        def to_px(dimension)
          scale = UNIT_SCALES[dimension.unit]
          scale ? dimension.length.to_f * scale : 0.0
        end

        def target_size(iw, ih, width, height)
          if width && height
            scale = [width.to_f / iw, height.to_f / ih].min
          elsif width
            scale = width.to_f / iw
          elsif height
            scale = height.to_f / ih
          else
            return [iw, ih]
          end

          [iw * scale, ih * scale]
        end

        def target_size?(format, width, height)
          return false if width <= 0 || height <= 0
          return false unless width.finite? && height.finite?
          return true unless format == :png

          width.round.positive? && height.round.positive?
        end
      end

      private_constant :Render

      # Low-level format renderers used by {Export.call}.
      # @api private
      module Renderer
        extend self

        # Renders SVG data to a PDF surface.
        # @param handle [Rsvg::Handle] parsed SVG handle
        # @param output [String] output file path
        # @param tw [Numeric] target width in CSS pixels
        # @param th [Numeric] target height in CSS pixels
        # @param dpi [Numeric] CSS pixel density
        # @return [void]
        # @raise [Cairo::Error] when Cairo cannot write the PDF surface
        # @raise [Rsvg::Error] when librsvg cannot render the document
        def pdf(handle:, output:, tw:, th:, dpi:)
          pw, ph = pdf_points(tw, th, dpi)
          surface = Cairo::PDFSurface.new(output, pw, ph)
          draw_pdf(surface, handle, [pw / tw, ph / th], [tw, th])
        ensure
          surface&.finish
        end

        # Renders SVG data to a PNG image.
        # @param handle [Rsvg::Handle] parsed SVG handle
        # @param output [String] output file path
        # @param tw [Numeric] target width in CSS pixels
        # @param th [Numeric] target height in CSS pixels
        # @return [void]
        # @raise [Cairo::Error] when Cairo cannot write the PNG surface
        # @raise [Rsvg::Error] when librsvg cannot render the document
        def png(handle:, output:, tw:, th:)
          surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, tw.round, th.round)
          context = Cairo::Context.new(surface)
          handle.render_document(context, viewport(tw, th))
          surface.write_to_png(output)
        end

        private

        def pdf_points(tw, th, dpi)
          factor = 72.0 / dpi
          [tw * factor, th * factor]
        end

        def draw_pdf(surface, handle, scale, size)
          context = Cairo::Context.new(surface)
          context.scale(*scale)
          handle.render_document(context, viewport(*size))
          context.show_page
        end

        def viewport(width, height)
          Rsvg::Rectangle.new.tap do |rectangle|
            rectangle.x = 0
            rectangle.y = 0
            rectangle.width = width
            rectangle.height = height
          end
        end
      end

      private_constant :Renderer
    end
  end
end
