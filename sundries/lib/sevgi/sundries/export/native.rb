# frozen_string_literal: true

require_relative "../export"

require "cairo"
require "fileutils"
require "hexapdf"
require "rsvg2"
require "stringio"
require "tempfile"

module Sevgi
  module Sundries
    module Export
      %i[
        call
        stamp
        stamp!
      ].each { remove_method(it) if method_defined?(it) }

      # Exports SVG source to a PDF or PNG file using librsvg and Cairo.
      # @param svg [String] SVG source content
      # @param output [String, #to_s] output file path
      # @param format [Symbol, String, nil] explicit output format, or nil to infer from output extension
      # @param width [Numeric, nil] finite positive target width in output pixels for PNG, or CSS pixels before PDF point conversion
      # @param height [Numeric, nil] finite positive target height in output pixels for PNG, or CSS pixels before PDF point conversion
      # @param dpi [Numeric] finite positive CSS pixel density used for absolute SVG units and PDF point conversion
      # @param css [String, nil] CSS inserted before the closing svg tag before rendering
      # @yield [svg] optional source transformation applied before rendering
      # @yieldparam svg [String] SVG source after optional CSS injection
      # @yieldreturn [String] SVG source to render
      # @return [Object] the original output argument
      # @raise [Sevgi::ArgumentError] when output, CSS, or transformed SVG has an invalid type
      # @raise [Sevgi::Sundries::Export::ExportError] when format, numeric options, SVG parsing, SVG dimensions, or render dimensions are invalid
      def call(svg, output, format: nil, width: nil, height: nil, dpi: DEFAULT_DPI, css: nil, &block)
        ArgumentError.("SVG content must be a String") unless svg.is_a?(String)
        original_output = output
        output = output_path(output)
        format = format_for!(format, output)
        width = dimension(width, "width")
        height = dimension(height, "height")
        dpi = dimension(dpi, "dpi")
        ArgumentError.("Export CSS must be a String") unless css.nil? || css.is_a?(String)

        svg = inject(svg, css) if css && !css.strip.empty?
        svg = block.call(svg) if block
        ArgumentError.("SVG content must be a String") unless svg.is_a?(String)

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
            output: output,
            iw: iw,
            ih: ih,
            tw: tw,
            th: th,
            dpi: dpi
          )
        rescue Rsvg::Error, Cairo::Error => e
          ExportError.("Render error: #{e.message}")
        end

        original_output
      end

      # Replaces exact placeholder text objects in PDF streams.
      # The placeholder must appear as a PDF literal string in a white text object matching the export stamp pattern.
      # Replacement text is escaped as a PDF literal string. When no exact match is replaced, the output file is not
      # written.
      # @param infile [String] source PDF file path
      # @param outfile [String] destination PDF file path
      # @param stamp [String] replacement text
      # @param placeholder [String] placeholder text to replace
      # @return [Boolean] true when at least one matching placeholder was replaced
      # @raise [Sevgi::Sundries::Export::ExportError] when the PDF cannot be read, rewritten, or stamped
      def stamp(infile, outfile, stamp:, placeholder:)
        doc = HexaPDF::Document.open(infile)
        replacements = 0

        doc.pages.each do |page|
          Array(page[:Contents]).each do |ref|
            obj = doc.object(ref)
            next unless obj.respond_to?(:stream)

            data, count = stamp_stream(obj.stream, stamp:, placeholder:)
            next if count.zero?

            replacements += count

            obj.stream = data
            obj.set_filter(:FlateDecode)
          end
        end

        doc.write(outfile, optimize: true) if replacements.positive?
        replacements.positive?
      rescue HexaPDF::Error, ::SystemCallError => e
        ExportError.("PDF stamp error: #{e.message}")
      end

      # Replaces exact placeholder text objects inside a PDF file in place.
      # The input file is replaced only after at least one exact placeholder match is rewritten into a non-empty output
      # file.
      # @param infile [String] PDF file path to modify
      # @param stamp [String] replacement text
      # @param placeholder [String] placeholder text to replace
      # @return [Boolean] true when at least one matching placeholder was replaced
      # @raise [Sevgi::Sundries::Export::ExportError] when the PDF cannot be read, rewritten, stamped, or replaced
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

      # Parses and rewrites supported PDF text operators without crossing text objects.
      # @api private
      module Stamp
        extend self

        PDF_LITERAL_ESCAPE = {
          "\\" => "\\\\",
          "(" => "\\(",
          ")" => "\\)",
          "\b" => "\\b",
          "\f" => "\\f",
          "\n" => "\\n",
          "\r" => "\\r",
          "\t" => "\\t"
        }.freeze

        private_constant :PDF_LITERAL_ESCAPE

        def replace(data, stamp:, placeholder:)
          replacements, count = replacements(data, stamp:, placeholder:)
          stamped = data.dup

          replacements.sort_by(&:first).reverse_each do |start, finish, replacement|
            stamped[start...finish] = replacement
          end

          [stamped, count]
        end

        private

        def pdf_literal(text)
          "(#{text.to_s.each_char.map { PDF_LITERAL_ESCAPE.fetch(it, it) }.join})"
        end

        def replacements(data, stamp:, placeholder:)
          tokenizer = HexaPDF::Tokenizer.new(::StringIO.new(data))
          serializer = HexaPDF::Serializer.new
          operands = []
          state = {
            fill_span: nil,
            fill_white: false,
            fill_replaced: false,
            font_size: nil,
            in_text: false,
            stack: []
          }
          replacements = []
          count = 0

          loop do
            start = tokenizer.pos
            object = tokenizer.next_object(allow_keyword: true)
            break if object.equal?(HexaPDF::Tokenizer::NO_MORE_TOKENS)

            finish = tokenizer.pos
            unless object.is_a?(HexaPDF::Tokenizer::Token)
              operands << [object, start, finish]
              next
            end

            count += process_operator(
              object.to_sym,
              operands,
              finish,
              data,
              stamp:,
              placeholder:,
              serializer:,
              state:,
              replacements:
            )

            operands.clear
          end

          [replacements, count]
        end

        def process_operator(operator, operands, finish, data, stamp:, placeholder:, serializer:, state:, replacements:)
          case operator
          when :q
            state[:stack] << state.values_at(:fill_span, :fill_white, :fill_replaced, :font_size)
          when :Q
            restore_state(state) if state[:stack].any?
          when :rg
            set_fill_state(state, operands, finish)
          when :BT
            state[:in_text] = true
          when :ET
            state[:in_text] = false
          when :Tf
            state[:font_size] = operands.last&.first if operands.size >= 2
          when :Tj, :"'", :"\"", :TJ
            return add_text_replacement(
              operator,
              operands,
              data,
              stamp:,
              placeholder:,
              serializer:,
              state:,
              replacements:
            )
          end

          0
        end

        def restore_state(state)
          state[:fill_span], state[:fill_white], state[:fill_replaced], state[:font_size] = state[:stack].pop
        end

        def set_fill_state(state, operands, finish)
          state[:fill_white] = operands.size == 3 && operands.all? { |value, _start, _finish| value == 1 }
          state[:fill_span] = [operands.first[1], finish] if state[:fill_white]
          state[:fill_replaced] = false
          state[:fill_span] = nil unless state[:fill_white]
        end

        def add_text_replacement(operator, operands, data, stamp:, placeholder:, serializer:, state:, replacements:)
          replacement = text_replacement(data, operator, operands, stamp:, placeholder:, serializer:, state:)
          return 0 unless replacement

          replacements << replacement
          add_color_replacement(data, state, replacements)
          1
        end

        def add_color_replacement(data, state, replacements)
          return unless state[:fill_span] && !state[:fill_replaced]

          color_start, color_finish = state[:fill_span]
          prefix = data[color_start...color_finish].to_s[/\A\s*/]
          replacements << [color_start, color_finish, "#{prefix}0.101961 0.101961 0.101961 rg"]
          state[:fill_replaced] = true
        end

        def text_replacement(data, operator, operands, stamp:, placeholder:, serializer:, state:)
          return unless state[:in_text] && state[:fill_white] && state[:font_size]

          case operator
          when :Tj, :"'", :"\""
            value, start, finish = operands.last || []
            return unless value.is_a?(String) && value == placeholder

            prefix = data[start...finish].to_s[/\A\s*/]
            [start, finish, "#{prefix}#{pdf_literal(stamp)}"]
          when :TJ
            value, start, finish = operands.last || []
            return unless value.is_a?(Array) && value.grep(String).join == placeholder

            prefix = data[start...finish].to_s[/\A\s*/]
            [start, finish, "#{prefix}#{serializer.serialize_array([stamp])}"]
          end
        end
      end

      private_constant :Stamp

      class << self
        private

        def output_path(output)
          ArgumentError.("Export output must be provided") if output.nil?

          path = output.to_s
          ArgumentError.("Export output must be a String-like path") unless path.is_a?(::String)
          ArgumentError.("Export output must be provided") if path.strip.empty?

          path
        rescue ::StandardError => e
          raise if e.is_a?(::Sevgi::ArgumentError)

          ArgumentError.("Export output must be a String-like path: #{e.message}")
        end

        def dimension(value, field)
          return if value.nil?
          ExportError.(dimension_error(field)) unless value.is_a?(::Numeric)

          number = begin
            value.to_f
          rescue ::StandardError => e
            ExportError.(dimension_error(field, e.message))
          end

          ExportError.(dimension_error(field)) unless number.is_a?(::Float) && number.finite? && number.positive?

          number
        end

        def dimension_error(field, detail = nil)
          message = [
            (%w[width height].include?(field) ? "Invalid export dimensions" : "Invalid export #{field}"),
            detail
          ]
          message.compact.join(": ")
        end

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

        def stamp_stream(data, stamp:, placeholder:)
          Stamp.replace(data, stamp:, placeholder:)
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

      private_constant :Renderer
    end
  end
end
