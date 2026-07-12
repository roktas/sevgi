# frozen_string_literal: true

require "tmpdir"

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class ExportTest < Minitest::Test
        BrokenPath = Class.new do
          def to_path = raise "broken path"
        end

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

        def test_exports_use_default_names_inside_directory
          require "sevgi/sundries"

          Dir.mktmpdir do |dir|
            calls = []

            exporter = proc do |_svg, output, **kwargs|
              calls << [output, kwargs]
              output
            end

            results = Sundries::Export.stub(:call, exporter) do
              document = SVG(:minimal)
              [document.PNG(dir), document.PDF(dir)]
            end

            expected = %w[png pdf].map { File.join(dir, "export_test.#{it}") }
            assert_equal(expected, results)
            assert_equal(
              [[expected[0], {format: :png}], [expected[1], {format: :pdf}]],
              calls
            )
          end
        end

        def test_export_normalizes_pathlike_outputs
          require "sevgi/sundries"

          Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
              calls = []
              exporter = proc do |_svg, output, **_kwargs|
                calls << output
                output
              end

              result = Sundries::Export.stub(:call, exporter) do
                SVG(:minimal).PNG(Pathname("nested/out.png"))
              end

              expected = File.expand_path("nested/out.png")
              assert_equal(expected, result)
              assert_instance_of(String, result)
              assert_equal([expected], calls)
            end
          end
        end

        def test_exports_reject_invalid_raw_paths_before_render
          require "sevgi/sundries"

          invalid = [false, "", " \t", Object.new, BrokenPath.new]
          document = SVG(:minimal)
          rendered = false
          exported = false
          exporter = proc { exported = true }

          document.stub(:call, -> { rendered = true }) do
            Sundries::Export.stub(:call, exporter) do
              invalid.each do |path|
                assert_raises(Sevgi::ArgumentError) { document.PDF(path) }
                assert_raises(Sevgi::ArgumentError) { document.PNG(path) }
                assert_raises(Sevgi::ArgumentError) { document.PDF(nil, default: path) }
                assert_raises(Sevgi::ArgumentError) { document.PNG(nil, default: path) }
              end
            end
          end

          refute(rendered)
          refute(exported)
        end

        def test_exports_accept_pathlike_explicit_defaults
          require "sevgi/sundries"

          Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
              Dir.mkdir("nested")
              outputs = Sundries::Export.stub(:call, -> (_svg, output, **) { output }) do
                document = SVG(:minimal)
                [
                  document.PDF(nil, default: Pathname("direct.pdf")),
                  document.PNG(Pathname("nested"), default: Pathname("named.png"))
                ]
              end

              assert_equal(
                [File.expand_path("direct.pdf"), File.expand_path("nested/named.png")],
                outputs
              )
            end
          end
        end

        def test_exports_derive_defaults_only_for_nil_paths
          require "sevgi/sundries"

          outputs = Sundries::Export.stub(:call, -> (_svg, output, **) { output }) do
            document = SVG(:minimal)
            [document.PDF(nil), document.PNG(nil)]
          end

          assert_equal(%w[export_test.pdf export_test.png], outputs.map { File.basename(it) })
          assert(outputs.all? { it.is_a?(String) && File.absolute_path?(it) })
        end

        def test_export_propagates_file_failures
          require "sevgi/sundries"

          failure = proc { |_svg, _output, **_kwargs| raise Errno::EACCES, "denied" }

          assert_raises(Errno::EACCES) do
            Sundries::Export.stub(:call, failure) { SVG(:minimal).PDF("out.pdf") }
          end
        end

        def test_exports_reject_unknown_options_before_render
          require "sevgi/sundries"

          document = SVG(:minimal)
          rendered = false
          exported = false

          document.stub(:call, -> { rendered = true }) do
            Sundries::Export.stub(:call, -> (*) { exported = true }) do
              assert_raises(Sevgi::ArgumentError) { document.PDF("out.pdf", typo: true) }
              assert_raises(Sevgi::ArgumentError) { document.PNG("out.png", typo: true) }
            end
          end

          refute(rendered)
          refute(exported)
        end
      end
    end
  end
end
