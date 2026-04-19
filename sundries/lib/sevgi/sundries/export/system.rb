# frozen_string_literal: true

require "fileutils"
require "tempfile"

module Sevgi
  module Sundries
    module Export
      # pdfcpu - https://pdfcpu.io/ (pdfcpu package)
      def a5ona4(infile, outfile) = F.sh!("pdfcpu", "nup", "--", "form:A4L, border:off", outfile, "2", infile)

      def a5ona4!(infile)
        temp = Tempfile.new(%w[output .pdf], File.dirname(infile))
        a5ona4(infile, temp.path)
        FileUtils.mv(temp.path, infile)
      ensure
        temp&.close!
      end

      # inkscape - https://inkscape.org/ (inkscape package)
      def inkscape(infile, outfile = nil,
                   format: nil, background: "#ffffff", opacity: 1, width: nil, height: nil, id: nil, page: nil, css: nil)
        infile  = File.expand_path(infile)
        outfile = File.expand_path(outfile ||= F.subext(".pdf", infile))
        format  = format_for!(format, outfile)

        if css
          temp = Tempfile.new(%w[input .svg], File.dirname(infile))
          ::File.write(temp.path, inject(::File.read(infile), css))
          infile = temp.path
        end

        F.sh!(*[
          "inkscape",
            "--batch-process",
            "--actions=select-by-class:text,object-to-path",
            "--export-type=#{format}",
            ("--export-background=#{background}" if background),
            ("--export-background-opacity=#{opacity}" if opacity),
            ("--export-width=#{width}" if width),
            ("--export-height=#{height}" if height),
            ("--export-id=#{id}" if id),
            ("--export-id-only" if id),
            ("--export-page=#{page}" if page),
            "--export-filename=#{outfile}",
            infile,
        ].compact)
      ensure
        temp&.close!
      end

      # rsvg-convert - https://gitlab.gnome.org/GNOME/librsvg (librsvg2-bin package)
      def rsvg(infile, outfile = nil,
               format: nil, background: "#ffffff", width: nil, height: nil, id: nil, css: nil)
        infile  = File.expand_path(infile)
        outfile = File.expand_path(outfile ||= F.subext(".pdf", infile))
        format  = format_for!(format, outfile)

        if css
          temp = Tempfile.new(%w[input .svg], File.dirname(infile))
          ::File.write(temp.path, inject(::File.read(infile), css))
          infile = temp.path
        end

        F.sh!(*[
          "rsvg-convert",
            "--format=#{format}",
            ("--background-color=#{background}" if background),
            ("--width=#{width}" if width),
            ("--height=#{height}" if height),
            ("--export-id=#{id}" if id),
            "--output=#{outfile}",
            infile,
        ].compact)
      ensure
        temp&.close!
      end

      # pdfunite - https://poppler.freedesktop.org/ (poppler-utils package)
      def unite(sources, outfile) = F.sh!("pdfunite", *sources, outfile)

      extend self
    end
  end
end
