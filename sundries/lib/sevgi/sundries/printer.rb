# frozen_string_literal: true

require "digest"
require "hexapdf"

module Sevgi
  module Sundries
    class Printer
      def self.call(source, verbose: false, simulate: false)  = new(source).call(verbose:, simulate:)
      def self.merge(...)                                     = PDF.merge(...)

      module PDF
        SHA1_PROPERTY = :source_sha1

        def sha1(file)
          return unless ::File.exist?(file)

          old_sha1 ||= HexaPDF::Document.open(file).trailer.info[SHA1_PROPERTY]
        end

        def merge(dest, *sources)
          F.sh!(*%W[
              hexapdf
              merge
              --force
              --compact
              --prune-page-resources
            ],
            *sources,
            dest
          )

          dest
        end

        def update(file, *sha1s)
          HexaPDF::Document.open(file).tap { it.trailer.info[SHA1_PROPERTY] = sha1s.join(" ") }.write(file, optimize: true)
        end

        extend self
      end

      attr_reader :source, :dest

      def initialize(source)
        @source = source
        @dest   = ext(source, "pdf")
      end

      def call(verbose: false, simulate: false)
        return unless update?

        F.do("Exporting to PDF") if verbose
        return if simulate

        export
        update!

        dest
      end

      private

        def export
          F.sh!(*%W[
            inkscape
            #{source}
            --export-area-page
            --batch-process
            --export-type=pdf
            --export-filename=#{dest}
          ])
        end

        # Adapted from ActiveSupport
        def ext(path, newext = "")
          return path if [ ".", ".." ].include? path

          if newext != ""
            newext = "." + newext unless newext =~ /^\./
          end

          path.chomp(File.extname(path)) << newext
        end

        def old_sha1
          PDF.sha1(dest)
        end

        def sha1
          @sha1 ||= Digest::SHA1.digest(::File.read(source))
        end

        def update!
          PDF.update(dest, sha1)
        end

        def update?
          old_sha1.nil? ? true : old_sha1 != sha1
        end
    end
  end
end
