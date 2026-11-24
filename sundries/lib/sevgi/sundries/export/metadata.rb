# frozen_string_literal: true

module Sevgi
  module Sundries
    module Export
      # Converts document RDF to PDF XMP without changing page content or adding dates.
      # @api private
      module Metadata
        DC = "http://purl.org/dc/elements/1.1/"
        RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        CC = "http://creativecommons.org/ns#"
        NS = {"svg" => "http://www.w3.org/2000/svg", "rdf" => RDF, "dc" => DC, "cc" => CC}.freeze
        FIELDS = %i[title description creator publisher date language license rights].freeze
        ARRAYS = {creator: "Seq", publisher: "Bag", date: "Seq", language: "Bag"}.freeze
        LIMIT = 16 * 1024 * 1024
        BLANK_XMP = "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\"><rdf:RDF xmlns:rdf=\"#{RDF}\"/></x:xmpmeta>".freeze

        class << self
          # Normalizes and validates caller-supplied PDF metadata fields.
          # @param fields [Hash] metadata fields
          # @return [Hash{Symbol => String, Array<String>}] frozen metadata snapshot
          # @raise [Sevgi::ArgumentError] when any field name or value is invalid
          def capture(fields) = Fields.capture(fields)

          # Extracts root SVG RDF metadata compatible with PDF XMP projection.
          # @param svg [String] rendered SVG source
          # @return [Hash{Symbol => String, Array<String>}] frozen extracted metadata
          # @raise [Sevgi::ArgumentError] when SVG metadata cannot be parsed or is ambiguous
          def from_svg(svg)
            return {}.freeze unless svg.include?("metadata")

            document = XML.parse(svg, limit: nil)
            resources = document.xpath("/svg:svg/svg:metadata/rdf:RDF/*", NS).select do |node|
              ["", nil].include?(node.attribute_with_ns("about", RDF)&.value)
            end

            Fields.capture(FIELDS.filter_map { |field| Fields.read(resources, field) }.to_h)
          end

          # Stages an export target and writes PDF metadata before atomic replacement.
          # @param output [String] expanded PDF destination path
          # @param fields [Hash] captured metadata fields
          # @yield [staged] produces the staged PDF prior to metadata rewriting
          # @yieldparam staged [String] staged PDF file path
          # @yieldreturn [Object] ignored producer return value
          # @return [String] expanded destination path
          def export(output, fields)
            Staging.replace(output, prefix: ".sevgi-xmp-", filename: "output.pdf") do |staged|
              yield staged
              write(staged, fields)
              true
            end

            output
          end

          # Updates XMP metadata and legacy trailer Info entries on an existing PDF.
          # @param path [String] PDF file path
          # @param fields [Hash] captured metadata fields
          # @return [void]
          # @raise [Sevgi::MissingComponentError] when hexapdf or nokogiri is unavailable
          # @raise [Sevgi::Sundries::Export::ExportError] when HexaPDF cannot read or write the PDF
          def write(path, fields)
            require "hexapdf"

            document = HexaPDF::Document.open(path)
            apply_metadata(document, fields)
            write_staged(document, path)
          rescue LoadError => e
            raise unless e.path == "hexapdf"

            MissingComponentError.("hexapdf")
          rescue HexaPDF::Error => e
            ExportError.("PDF metadata error: #{e.message}")
          end

          private

          def apply_metadata(document, fields)
            payload = Packet.build(document.catalog[:Metadata]&.stream, fields)
            document.catalog[:Metadata] = document.add({Type: :Metadata, Subtype: :XML}, stream: payload)
            update_trailer(document, fields)
          end

          def update_trailer(document, fields)
            {title: :Title, description: :Subject, creator: :Author}.each do |key, entry|
              next unless fields.key?(key)

              document.trailer[:Info] ||= {}
              document.trailer[:Info][entry] = Array(fields.fetch(key)).join("; ")
            end
          end

          def write_staged(document, path)
            Staging.replace(path, prefix: ".sevgi-xmp-", filename: "output.pdf") do |staged|
              document.write(staged, validate: false, update_fields: false)
              true
            end
          end
        end
      end

      require_relative "metadata/fields"
      require_relative "metadata/packet"

      private_constant :Metadata
    end
  end
end
