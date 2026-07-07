# frozen_string_literal: true

require "tmpdir"

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class ExportTest < Minitest::Test
        def test_png_delegates_to_sundries_export
          require "sevgi/sundries"

          Dir.mktmpdir do |dir|
            path = File.join(dir, "out.png")
            calls = []

            exporter = proc do |svg, output, **kwargs|
              calls << [svg, output, kwargs]
              output
            end

            result = Sundries::Export.stub(:call, exporter) do
              SVG(:minimal) { rect(id: "one") }.PNG(path, width: 32)
            end

            [
              path,
              result,
              ["<svg>\n  <rect id=\"one\"/>\n</svg>", path, {width: 32, format: :png}],
              calls.first
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end
        end

        def test_pdf_uses_pdf_format_by_default
          require "sevgi/sundries"

          Dir.mktmpdir do |dir|
            path = File.join(dir, "out.pdf")
            calls = []

            exporter = proc do |_svg, output, **kwargs|
              calls << [output, kwargs]
              output
            end

            result = Sundries::Export.stub(:call, exporter) do
              SVG(:minimal).PDF(path)
            end

            [
              path,
              result,
              [path, {format: :pdf}],
              calls.first
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end
        end

        def test_png_uses_default_name_inside_directory
          require "sevgi/sundries"

          Dir.mktmpdir do |dir|
            calls = []

            exporter = proc do |_svg, output, **kwargs|
              calls << [output, kwargs]
              output
            end

            result = Sundries::Export.stub(:call, exporter) do
              SVG(:minimal).PNG(dir)
            end

            expected = File.join(dir, "export_test.png")
            [
              expected,
              result,
              [expected, {format: :png}],
              calls.first
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end
        end
      end
    end
  end
end
