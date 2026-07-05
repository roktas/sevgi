# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    class ContentTest < Minitest::Test
      def test_cdata_content_renders_block
        expected = <<~SVG
          <svg>
            <style>
              <![CDATA[
                a & b
                c < d
              ]]>
            </style>
          </svg>
        SVG
          .chomp

        actual = SVG(:minimal) do
          style(Content.cdata(["a & b", "c < d"]))
        end
          .Render()

        assert_equal(expected, actual)
      end

      def test_encoded_and_verbatim_content_differ
        [
          "a &amp; b",
          Content.encoded("a & b").to_s,
          "a & b",
          Content.verbatim("a & b").to_s
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
