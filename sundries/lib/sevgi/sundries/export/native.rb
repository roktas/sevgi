# frozen_string_literal: true

require_relative "../export"

require "cairo"
require "hexapdf"
require "rsvg2"
require "stringio"

module Sevgi
  module Sundries
    module Export
      %i[
        stamp
        stamp!
      ].each { remove_method(it) if method_defined?(it) }

      # Renders validated, transformed SVG through librsvg and Cairo.
      # @api private
      def render(svg, output, format:, width:, height:, dpi:)
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

          Staging.replace(output, prefix: ".sevgi-render-", filename: "output.#{format}") do |staged|
            renderer.call(
              handle: handle,
              output: staged,
              iw: iw,
              ih: ih,
              tw: tw,
              th: th,
              dpi: dpi
            )
            true
          end

        rescue Rsvg::Error, Cairo::Error => e
          ExportError.("Render error: #{e.message}")
        end

        output
      end

      private :render

      # @api private
      def stamp_forms(document, stamp:, placeholder:)
        pending = document.pages.flat_map do |page|
          objects = page[:Resources]&.[](:XObject)
          objects ? objects.each.map { |_name, value| value } : []
        end

        seen = {}
        replacements = 0
        until pending.empty?
          form = pending.pop
          next unless form.is_a?(HexaPDF::Stream) && form[:Subtype] == :Form
          identity = [form.oid, form.gen]
          next if seen[identity]
          seen[identity] = true
          objects = form[:Resources]&.[](:XObject)
          pending.concat(objects ? objects.each.map { |_name, value| value } : [])
          data, count = stamp_stream(form.stream, stamp:, placeholder:)
          next if count.zero?
          replacements += count
          form.stream = data
          form.set_filter(:FlateDecode)
        end

        replacements
      end

      private :stamp_forms

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
      # @note Pages with inline images, unknown operators, or unbalanced graphics-state/text-object operators are left unchanged.
      def stamp(infile, outfile, stamp:, placeholder:)
        doc = HexaPDF::Document.open(infile)
        replacements = 0

        doc.pages.each do |page|
          data, count = stamp_stream(page.contents, stamp:, placeholder:)
          next if count.zero?

          replacements += count
          page.contents = data
          doc.deref(page[:Contents]).set_filter(:FlateDecode)
        end

        replacements += stamp_forms(doc, stamp:, placeholder:)
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
      # @note Pages with inline images, unknown operators, or unbalanced graphics-state/text-object operators are left unchanged.
      def stamp!(infile, stamp:, placeholder:)
        stamped = false
        Staging.workspace(infile, prefix: ".sevgi-stamp-") do |directory|
          staged = ::File.join(directory, "output.pdf")
          stamped = stamp(infile, staged, stamp:, placeholder:)
          if stamped
            if ::File.exist?(staged) && ::File.empty?(staged)
              warn("Skipping 0 byte file which was produced during stamping")
            else
              ::File.rename(staged, infile)
            end
          end
        end

        stamped
      rescue ::SystemCallError => e
        ExportError.("PDF stamp error: #{e.message}")
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

        PDF_SEPARATOR = %r{\A[\s\x00()<>\[\]{}/%]}n
        private_constant :PDF_SEPARATOR

        def replace(data, stamp:, placeholder:)
          binary = data.b
          edits, count = replacements(binary, stamp:, placeholder:)
          stamped = binary.dup

          edits
            .each_with_index
            .sort_by { |(start, _finish, _text), index| [-start, -index] }
            .each { |(start, finish, text), _index| stamped[start...finish] = text }

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
            fill_white: false,
            font_size: nil,
            in_text: false,
            stack: [],
            valid: true
          }
          edits = []
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

            # Inline image bytes are not PDF tokens; never interpret them as operators.
            operator = object.to_sym
            return [[], 0] if operator == :BI || !HexaPDF::Content::Processor::OPERATOR_MESSAGE_NAME_MAP.key?(operator)

            count += process_operator(
              operator,
              operands,
              finish,
              data,
              stamp:,
              placeholder:,
              serializer:,
              state:,
              edits:
            )

            operands.clear
          end

          state[:valid] && state[:stack].empty? && !state[:in_text] ? [edits, count] : [[], 0]
        end

        def process_operator(operator, operands, finish, data, stamp:, placeholder:, serializer:, state:, edits:)
          case operator
          when :q
            state[:stack] << state.values_at(:fill_white, :font_size)
          when :Q
            state[:stack].any? ? restore_state(state) : state[:valid] = false
          when :rg
            set_fill_state(state, operands)
          when :g, :k, :cs, :sc, :scn
            state[:fill_white] = false
          when :BT
            state[:valid] = false if state[:in_text]
            state[:in_text] = true
          when :ET
            state[:valid] = false unless state[:in_text]
            state[:in_text] = false
          when :Tf
            state[:font_size] = operands.last&.first if operands.size >= 2
          when :Tj, :"'", :"\"", :TJ
            return add_text_replacement(
              operator,
              operands,
              data,
              operator_finish: finish,
              stamp:,
              placeholder:,
              serializer:,
              state:,
              edits:
            )
          end

          0
        end

        def restore_state(state)
          state[:fill_white], state[:font_size] = state[:stack].pop
        end

        def set_fill_state(state, operands)
          state[:fill_white] = operands.size == 3 && operands.all? { |value, _start, _finish| value == 1 }
        end

        def add_text_replacement(
          operator,
          operands,
          data,
          operator_finish:,
          stamp:,
          placeholder:,
          serializer:,
          state:,
          edits:
        )
          replacement = text_replacement(data, operator, operands, stamp:, placeholder:, serializer:, state:)
          return 0 unless replacement

          start, text_finish, text = replacement
          color_start = operands.first.fetch(1)
          text = " 0.101961 0.101961 0.101961 rg#{text}" if start == color_start
          edits << [start, text_finish, text.b]
          add_color_replacement(color_start, data, edits) unless start == color_start
          edits << [operator_finish, operator_finish, " 1 1 1 rg#{suffix_space(data, operator_finish)}".b]
          1
        end

        def add_color_replacement(start, data, edits)
          edits << [start, start, " 0.101961 0.101961 0.101961 rg#{suffix_space(data, start)}".b]
        end

        def suffix_space(data, pos)
          return "" unless pos < data.bytesize

          PDF_SEPARATOR.match?(data.byteslice(pos, 1)) ? "" : " "
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
