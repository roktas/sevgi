# frozen_string_literal: true

require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Derender
    class DocumentTest < Minitest::Test
      def test_declaration_extracts_xml_declaration
        svg = <<~SVG
          <?xml version="1.0" encoding="UTF-8" standalone="no"?>
          <?my-app config="true"?>
          <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
          <svg xmlns="http://www.w3.org/2000/svg">
            <rect width="100" height="100" />
          </svg>
        SVG
          .chomp

        actual = Derender::Document.declaration(svg)
        expected = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>"

        assert_equal(expected, actual)
      end

      def test_declaration_stops_at_xml_token_boundary
        svg = "<?xml version=\"1.0\"?><svg/>"

        actual = Derender::Document.declaration(svg)

        assert_equal("<?xml version=\"1.0\"?>", actual)
      end

      def test_decompile_locates_id_with_quotes
        svg = <<~SVG
          <svg>
            <g id="a&quot;'b"/>
          </svg>
        SVG
          .chomp

        actual = Derender::Document.new(svg).decompile("a\"'b").attributes

        assert_equal({"id" => "a\"'b"}, actual)
      end

      def test_load_file_reparses_changed_content
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "changed.svg")
          ::File.write(file, "<svg id=\"root\"/>")

          assert_equal({"id" => "root"}, Derender::Document.load_file(file).decompile.attributes)

          ::File.write(file, "<svg id=\"updated\"/>")

          assert_equal({"id" => "updated"}, Derender::Document.load_file(file).decompile.attributes)
        end
      end

      def test_load_file_returns_isolated_documents
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "isolated.svg")
          ::File.write(file, "<svg id=\"root\"/>")
          first = Derender::Document.load_file(file)
          first.doc.root["id"] = "mutated"

          actual = Derender::Document.load_file(file).decompile.attributes

          assert_equal({"id" => "root"}, actual)
        end
      end

      def test_load_file_qualifies_svg_extension
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "drawing.svg")
          ::File.write(file, "<svg id=\"root\"/>")

          actual = Derender::Document.load_file(::File.join(dir, "drawing")).decompile("root")

          assert_equal({"id" => "root"}, actual.attributes)
        end
      end

      def test_new_wraps_malformed_xml_as_argument_error
        error = assert_raises(ArgumentError) do
          Derender::Document.new("<svg><g></svg>")
        end

        assert_match(/Malformed XML/, error.message)
        assert_instance_of(Nokogiri::XML::SyntaxError, error.cause)
      end

      def test_decompile_rejects_comment_only_document
        error = assert_raises(ArgumentError) do
          Derender::Document.new("<!-- no root -->").decompile
        end

        assert_match(/\A(?:Malformed XML|XML document has no root element)/, error.message)
      end

      def test_decompile_rejects_rootless_document
        rootless = Nokogiri::XML::Document.new

        Derender::Document.stub(:parse, rootless) do
          error = assert_raises(ArgumentError) do
            Derender::Document.new("<svg/>").decompile
          end

          assert_equal("XML document has no root element", error.message)
        end
      end

      def test_pres_extracts_preambles
        svg = <<~SVG

          <?xml version="1.0" encoding="UTF-8" standalone="no"?>
          <?my-app config="true"?>
          <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
          <svg xmlns="http://www.w3.org/2000/svg">
            <rect width="100" height="100" />
          </svg>

        SVG
          .chomp

        actual = Derender::Document.new(svg).pres

        expected = [
          "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>",
          "<?my-app config=\"true\"?>",
          "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">"
        ]

        assert_equal(expected, actual)
      end
    end
  end
end
