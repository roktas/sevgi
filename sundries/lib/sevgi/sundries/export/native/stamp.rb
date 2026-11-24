# frozen_string_literal: true

module Sevgi
  module Sundries
    module Export
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
        PDF_SEPARATOR = %r{\A[\s\x00()<>\[\]{}/%]}n
        STAMP_GRAY = "0.101961 0.101961 0.101961"
        STAMP_WHITE = "1 1 1"
        private_constant :PDF_LITERAL_ESCAPE, :PDF_SEPARATOR, :STAMP_GRAY, :STAMP_WHITE

        # Rewrites exact placeholder matches inside a single PDF content stream.
        # @param data [String] raw PDF content stream bytes
        # @param stamp [String] replacement text
        # @param placeholder [String] placeholder text to replace
        # @return [Array(String, Integer)] rewritten stream bytes and replacement count
        def replace(data, stamp:, placeholder:)
          binary = data.b
          edits, count = Scanner.new(binary, stamp:, placeholder:).scan
          stamped = binary.dup

          edits
            .each_with_index
            .sort_by { |(start, _finish, _text), index| [-start, -index] }
            .each { |(start, finish, text), _index| stamped[start...finish] = text }

          [stamped, count]
        end

        # Replaces exact placeholder text objects in PDF streams across pages and form XObjects.
        # @param infile [String] source PDF file path
        # @param outfile [String] destination PDF file path
        # @param stamp [String] replacement text
        # @param placeholder [String] placeholder text to replace
        # @return [Boolean] true when at least one matching placeholder was replaced
        # @raise [Sevgi::Sundries::Export::ExportError] when the PDF cannot be read, rewritten, or stamped
        def stamp(infile, outfile, stamp:, placeholder:)
          doc = HexaPDF::Document.open(infile)
          replacements = stamp_pages(doc, stamp:, placeholder:) + stamp_forms(doc, stamp:, placeholder:)
          doc.write(outfile, optimize: true) if replacements.positive?
          replacements.positive?
        rescue HexaPDF::Error, ::SystemCallError => e
          ExportError.("PDF stamp error: #{e.message}")
        end

        # Replaces exact placeholder text objects inside a PDF file in place.
        # @param infile [String] PDF file path to modify
        # @param stamp [String] replacement text
        # @param placeholder [String] placeholder text to replace
        # @return [Boolean] true when at least one matching placeholder was replaced
        # @raise [Sevgi::Sundries::Export::ExportError] when the PDF cannot be read, rewritten, stamped, or replaced
        def stamp!(infile, stamp:, placeholder:)
          stamped = false
          Staging.workspace(infile, prefix: ".sevgi-stamp-") do |directory|
            staged = ::File.join(directory, "output.pdf")
            stamped = Export.stamp(infile, staged, stamp:, placeholder:)
            commit_stamped(staged, infile) if stamped
          end

          stamped
        rescue ::SystemCallError => e
          ExportError.("PDF stamp error: #{e.message}")
        end

        def pdf_literal(text) = "(#{text.to_s.each_char.map { PDF_LITERAL_ESCAPE.fetch(it, it) }.join})"

        def tint_edit(data, pos, white: false)
          [pos, pos, " #{white ? STAMP_WHITE : STAMP_GRAY} rg#{suffix_space(data, pos)}".b]
        end

        def suffix_space(data, pos)
          pos < data.bytesize && !PDF_SEPARATOR.match?(data.byteslice(pos, 1)) ? " " : ""
        end

        private

        def commit_stamped(staged, infile)
          if ::File.exist?(staged) && ::File.empty?(staged)
            warn("Skipping 0 byte file which was produced during stamping")
          else
            ::File.rename(staged, infile)
          end
        end

        def stamp_pages(doc, stamp:, placeholder:)
          doc.pages.sum do |page|
            data, count = replace(page.contents, stamp:, placeholder:)
            next 0 if count.zero?

            page.contents = data
            doc.deref(page[:Contents]).set_filter(:FlateDecode)
            count
          end
        end

        def stamp_forms(document, stamp:, placeholder:)
          pending = form_xobjects(document.pages)
          seen = {}
          replacements = 0

          until pending.empty?
            form = pending.pop
            next unless form_xobject?(form, seen)

            pending.concat(form_xobjects([form]))
            replacements += rewrite_form(form, stamp:, placeholder:)
          end

          replacements
        end

        def form_xobject?(form, seen)
          return false unless form.is_a?(HexaPDF::Stream) && form[:Subtype] == :Form

          identity = [form.oid, form.gen]
          seen[identity] ? false : seen[identity] = true
        end

        def form_xobjects(owners)
          owners.flat_map { |owner| (objs = owner[:Resources]&.[](:XObject)) ? objs.each.map { _2 } : [] }
        end

        def rewrite_form(form, stamp:, placeholder:)
          data, count = replace(form.stream, stamp:, placeholder:)
          return 0 if count.zero?

          form.stream = data
          form.set_filter(:FlateDecode)
          count
        end
      end

      require_relative "stamp/scanner"

      private_constant :Stamp

      def stamp_stream(data, stamp:, placeholder:)
        Stamp.replace(data, stamp:, placeholder:)
      end

      private :stamp_stream
    end
  end
end
