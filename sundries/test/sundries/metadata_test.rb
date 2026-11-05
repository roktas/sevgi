# frozen_string_literal: true

require "hexapdf"
require "nokogiri"
require "stringio"
require "tmpdir"
require_relative "../test_helper"

module Sevgi
  module Sundries
    class MetadataTest < Minitest::Test
      NS = {
        "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        "dc" => "http://purl.org/dc/elements/1.1/"
      }.freeze

      def setup
        @directory = Dir.mktmpdir("sevgi-xmp")
        @output = File.join(@directory, "output.pdf")
        @fields = {title: "Arches & Loops", description: "Stroke practice.", creator: "Recai Oktaş", rights: "Copyright © 2026 Recai Oktaş. All rights reserved."}
        @drawing = Graphics.SVG(:inkscape, width: 40, height: 30) do
          g(id: "ink") { rect(width: 10, height: 10, fill: "none", stroke: "black") }
        end
        @drawing.License(**@fields)
      end

      def teardown = FileUtils.remove_entry(@directory)

      def test_rdf_reaches_xmp_in_ordinary_and_prepared_exports
        declaration = {
          targets: {ink: {selectors: ["#ink"]}},
          parameters: {opacity: {schema: {type: "number", minimum: 0, maximum: 1}, binding: {targets: ["ink"], property: "stroke-opacity"}}}
        }
        # ImprintTest covers the optional CLI transport; this fixture isolates PDF metadata rewriting.
        producer = -> (_input, path) do
          document = HexaPDF::Document.new
          document.pages.add
          document.files.add(StringIO.new("controls"), name: "controls.txt")
          document.write(path)
        end
        Imprint.stub(:write, producer) do
          [nil, declaration].each do |controls|
            Export.call(@drawing.Render, @output, declaration: controls, fallback: false)
            document = HexaPDF::Document.open(@output)
            xmp = Nokogiri::XML(document.catalog[:Metadata].stream)
            {title: "Alt", description: "Alt", creator: "Seq", rights: "Alt"}.each do |key, kind|
              assert_equal(@fields.fetch(key), xmp.at_xpath("//dc:#{key}/rdf:#{kind}/rdf:li", NS).text)
            end
            assert_equal("Arches & Loops", document.trailer[:Info][:Title])
            assert_equal("Stroke practice.", document.trailer[:Info][:Subject])
            assert_equal("Recai Oktaş", document.trailer[:Info][:Author])
            assert_equal(1, document.pages.count)
            assert(document.catalog[:Names][:EmbeddedFiles].each_entry.to_h.key?("controls.txt")) if controls
          end
        end
      end

      def test_publication_metadata_preserves_other_xmp_and_attachments
        Export.call(@drawing.Render, @output)
        document = HexaPDF::Document.open(@output)
        document.files.add(StringIO.new("notes"), name: "notes.txt")
        xml = Nokogiri::XML(document.catalog[:Metadata].stream)
        description = xml.at_xpath("//rdf:Description", NS)
        description.add_namespace_definition("mainz", "https://github.com/roktas/mainz/ns/1.0/")
        node = Nokogiri::XML::Node.new("coverPage", xml)
        node.namespace = description.namespace_definitions.find { it.prefix == "mainz" }
        node.content = "1"
        description.add_child(node)
        document.catalog[:Metadata].stream = xml.to_xml
        source = File.join(@directory, "source.pdf")
        document.write(source)
        Export.metadata(source, @output, title: "Publication", creator: %w[First Second])
        output = HexaPDF::Document.open(@output)
        data = Nokogiri::XML(output.catalog[:Metadata].stream)
        assert_equal("Publication", data.at_xpath("//dc:title/rdf:Alt/rdf:li", NS).text)
        assert_equal(%w[First Second], data.xpath("//dc:creator/rdf:Seq/rdf:li", NS).map(&:text))
        assert_equal("1", data.at_xpath("//*[local-name()='coverPage']").text)
        assert_equal(@fields.fetch(:rights), data.at_xpath("//dc:rights/rdf:Alt/rdf:li", NS).text)
        assert_equal("notes", output.catalog[:Names][:EmbeddedFiles].each_entry.to_h.fetch("notes.txt")[:EF][:F].stream)
      end

      def test_invalid_metadata_preserves_existing_output
        File.write(@output, "previous output")
        [{unknown: "text"}, {title: ""}, {rights: "bad\0text"}, {creator: []}].each do |fields|
          assert_raises(Sevgi::ArgumentError) { Export.metadata!(@output, **fields) }
          assert_equal("previous output", File.read(@output))
        end
      end

      def test_all_rdf_fields_use_their_xmp_types_without_adding_dates
        @drawing = Graphics.SVG(:inkscape, width: 20, height: 20) { rect(width: 10, height: 10) }
        @drawing.License(**@fields, publisher: "Publisher", date: "2026-11-05", language: "en", license: "https://example.test/license")
        Export.call(@drawing.Render, @output)
        xml = Nokogiri::XML(HexaPDF::Document.open(@output).catalog[:Metadata].stream)
        {publisher: "Bag", date: "Seq", language: "Bag"}.each do |field, kind|
          assert_equal(1, xml.xpath("//dc:#{field}/rdf:#{kind}/rdf:li", NS).length)
        end
        license = xml.at_xpath("//*[local-name()='license']")
        assert_equal("https://example.test/license", license.attribute_with_ns("resource", NS.fetch("rdf")).value)
        assert_empty(xml.xpath("//*[local-name()='CreateDate' or local-name()='ModifyDate']"))
      end

      def test_unsupported_language_alternatives_preserve_existing_output
        svg = @drawing.Render.sub("Arches &amp; Loops", '<rdf:Alt><rdf:li xml:lang="tr">Başlık</rdf:li></rdf:Alt>')
        File.write(@output, "previous output")
        assert_raises(Sevgi::ArgumentError) { Export.call(svg, @output) }
        assert_equal("previous output", File.read(@output))
      end

      def test_unreadable_pdf_preserves_existing_output
        File.write(@output, "previous output")
        assert_raises(Export::ExportError) { Export.metadata!(@output, title: "Title") }
        assert_equal("previous output", File.read(@output))
        assert_equal(["output.pdf"], Dir.children(@directory))
      end

      def test_failed_preparation_with_rdf_does_not_create_output_parents
        output = File.join(@directory, "nested", "output.pdf")
        producer = -> (*) { raise Imprint::Error, "Failed preparation" }
        Imprint.stub(:write, producer) do
          assert_raises(Imprint::Error) do
            Export.call(@drawing.Render, output, declaration: {targets: {}, parameters: {}}, fallback: false)
          end
        end
        refute_path_exists(File.dirname(output))
        assert_empty(Dir.children(@directory))
      end

      def test_ambiguous_root_rdf_fails_before_export
        @drawing.License(title: "Another title")
        File.write(@output, "previous output")
        assert_raises(Sevgi::ArgumentError) { Export.call(@drawing.Render, @output) }
        assert_equal("previous output", File.read(@output))
      end

      def test_nested_artwork_metadata_does_not_become_document_xmp
        drawing = Graphics.SVG(:inkscape, width: 30, height: 20) do
          g do
            License(title: "Other work")
          end
          rect(width: 10, height: 10)
        end
        Export.call(drawing.Render, @output)
        assert_nil(HexaPDF::Document.open(@output).catalog[:Metadata])
      end
    end
  end
end
