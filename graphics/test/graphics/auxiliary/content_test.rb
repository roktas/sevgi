# frozen_string_literal: true

require "nokogiri"

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

      def test_base_content_render_raises_panic_error
        assert_raises(PanicError) { Content.new("text").render(Object.new, 0) }
      end

      def test_encoded_and_verbatim_content_differ
        [
          "a &amp; b",
          Content.encoded("a & b").to_s,
          "a & b",
          Content.verbatim("a & b").to_s
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_encoded_content_stringifies_objects
        expected = <<~SVG
          <svg>
            <text>1 &amp; 2</text>
          </svg>
        SVG
          .chomp

        actual = SVG(:minimal) do
          text(Content.encoded(:"1 & 2"))
        end
          .Render()

        assert_render(expected, actual)
      end

      def test_cdata_splits_section_terminators
        actual = SVG(:minimal) do
          style(Content.cdata("a]]>b"))
        end
          .Render()

        assert_includes(actual, "]]]]><![CDATA[>")
        assert_equal("a]]>b", assert_render(actual, actual).at_css("style").text.strip)
      end

      def test_mixed_content_renders_valid_xml
        actual = SVG(:minimal) do
          text("1") do
            tspan(Content.encoded(:" & 2"))
          end
        end
          .Render()

        assert_render(actual, actual)
      end

      private

      def assert_render(expected, actual)
        assert_equal(expected, actual)

        Nokogiri::XML(actual, &:strict)
      end
    end
  end
end
