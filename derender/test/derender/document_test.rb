# frozen_string_literal: true

require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Derender
    class DocumentTest < Minitest::Test
      def teardown
        Derender::Document.cache.clear
      end

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

      def test_load_file_caches_parsed_document
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "cached.svg")
          ::File.write(file, "<svg id=\"root\"/>")
          calls = 0

          Derender::Document.stub(
            :parse,
            -> (content) {
              calls += 1
              Nokogiri::XML(content)
            }
          ) do
            2.times { Derender::Document.load_file(file).decompile("root") }
          end

          assert_equal(1, calls)
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
