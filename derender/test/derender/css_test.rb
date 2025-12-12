# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Graphics::Document
    class Test < Base
      document :test, attributes: { "data-var": "xxx" }
    end
  end

  module Derender
    class CSSTest < Minitest::Test
      DOC = :test

      def test_simple
        expected = <<~SVG.chomp
          <svg data-var="xxx">
            <line data-var="main var"/>
            <line data-var="duplicated var"/>
          </svg>
        SVG

        actual = SVG DOC do
          line("data-var": "main var").Duplicate[:"data-var"] = "duplicated var"
        end.Render

        assert_equal(expected, actual)
      end
    end
  end
end
