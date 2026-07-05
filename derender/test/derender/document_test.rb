# frozen_string_literal: true

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
