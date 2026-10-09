# frozen_string_literal: true

require "json"
require "rbconfig"
require "tmpdir"
require "hexapdf"
require_relative "../test_helper"

module Sevgi
  module Sundries
    class MainzTest < Minitest::Test
      def setup
        @directory = Dir.mktmpdir("sevgi-mainz-test")
        @path = ENV.fetch("PATH", nil)
        @program = File.join(@directory, "mainz")
        @output = File.join(@directory, "drawing.pdf")
        @svg = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><g id="ink"><rect width="10" height="10" fill="none" stroke="black"/></g></svg>'
        @style = {targets: {ink: {selectors: ["#ink"]}}, parameters: {
          display: {schema: {type: "string", enum: %w[inline none]}, binding: {targets: ["ink"], property: "display"}},
          opacity: {schema: {type: "number", minimum: 0, maximum: 1}, binding: {targets: ["ink"], property: "stroke-opacity"}}
        }}
        ENV["PATH"] = @directory
      end

      def teardown
        @path ? ENV["PATH"] = @path : ENV.delete("PATH")
        FileUtils.remove_entry(@directory)
      end

      def test_style_uses_cli_with_export_dimensions_and_callback
        producer
        callbacks = 0
        result = Export.call(@svg, @output, style: @style, width: 40, dpi: 144,
          css: "rect { stroke: red; }") do |source|
          callbacks += 1
          source
        end
        output = JSON.parse(File.read(@output).lines.drop(1).join)
        assert_equal(@output, result)
        assert_equal(1, callbacks)
        assert_includes(output.fetch("svg"), "rect { stroke: red; }")
        assert_equal(JSON.parse(JSON.generate(@style)), output.fetch("style"))
        assert_equal("40.0", output.fetch("options").fetch("--width"))
        assert_equal("144.0", output.fetch("options").fetch("--dpi"))
        assert_equal(%w[drawing.pdf mainz], Dir.children(@directory).sort)
      end

      def test_missing_cli_warns_and_exports_an_ordinary_pdf
        _out, warning = capture_io { Export.call(@svg, @output, style: @style) }
        assert_match(/Mainz executable is unavailable/, warning)
        assert_match(/without editable styles/, warning)
        assert_equal(1, HexaPDF::Document.open(@output).pages.count)
      end

      def test_explicit_produce_uses_the_same_validation_and_staging
        producer
        destination = File.join(@directory, "nested", "drawing.pdf")
        assert_equal(destination, Mainz.produce(@svg, destination, declaration: @style))
        assert_path_exists(destination)
        assert_raises(Sevgi::ArgumentError) { Mainz.produce(nil, destination, declaration: @style) }
        assert_raises(Sevgi::ArgumentError) { Mainz.produce(@svg, "", declaration: @style) }
        assert_raises(Export::ExportError) { Mainz.produce(@svg, destination, declaration: @style, dpi: 0) }
      end

      def test_failed_preparation_does_not_create_output_parents
        producer(status: 1)
        destination = File.join(@directory, "nested", "drawing.pdf")
        assert_raises(Mainz::Error) { Mainz.produce(@svg, destination, declaration: @style) }
        refute_path_exists(File.dirname(destination))
      end

      def test_failed_cli_reuses_the_transformed_source_for_fallback
        producer(status: 1)
        calls = 0
        _out, warning = capture_io do
          Export.call(@svg, @output, style: @style) do |source|
            calls += 1
            source.sub('width="20"', 'width="40"')
          end
        end
        assert_equal(1, calls)
        assert_match(/unsupported preparation/, warning)
        assert_in_delta(30.0, HexaPDF::Document.open(@output).pages.first.box.width, 1e-6)
        refute(Dir.children(@directory).any? { it.start_with?(".sevgi-mainz-") })
      end

      def test_no_fallback_preserves_existing_output
        File.write(@output, "previous")
        [nil, 1].each do |status|
          producer(status:) if status
          assert_raises(Mainz::Error) { Export.call(@svg, @output, style: @style, fallback: false) }
          assert_equal("previous", File.read(@output))
        end
        assert_equal(%w[drawing.pdf mainz], Dir.children(@directory).sort)
      end

      def test_interrupt_does_not_fall_back
        File.write(@output, "previous")
        [nil, "INT", "TERM", "KILL"].each do |signal|
          producer(status: 130, signal:)
          _out, warning = capture_io do
            assert_raises(Interrupt) { Export.call(@svg, @output, style: @style) }
          end
          assert_empty(warning)
          assert_equal("previous", File.read(@output))
        end
      end

      def test_unstyled_export_allows_disabled_fallback
        producer(status: 1)
        _out, warning = capture_io { Export.call(@svg, @output, fallback: false) }
        assert_empty(warning)
        assert_equal(1, HexaPDF::Document.open(@output).pages.count)
      end

      def test_invalid_arguments_preserve_output_in_both_modes
        producer
        File.write(@output, "previous")
        cycle = []
        cycle << cycle
        [true, false].each do |fallback|
          [Object.new, {a: 1, "a" => 2}, {values: cycle}, {value: Float::NAN}].each do |style|
            assert_raises(Sevgi::ArgumentError) { Export.call(@svg, @output, style:, fallback:) }
            assert_equal("previous", File.read(@output))
          end
        end
        [nil, 0, :auto].each do |fallback|
          assert_raises(Sevgi::ArgumentError) { Export.call(@svg, @output, fallback:) }
          assert_equal("previous", File.read(@output))
        end
        assert_raises(Sevgi::ArgumentError) { Mainz.produce(@svg, @output, declaration: nil) }
        assert_equal("previous", File.read(@output))
      end

      def test_source_callback_cannot_change_captured_declaration
        producer
        expected = JSON.parse(JSON.generate(@style))
        Export.call(@svg, @output, style: @style) do |source|
          @style.clear
          source
        end
        output = JSON.parse(File.read(@output).lines.drop(1).join)
        assert_equal(expected, output.fetch("style"))
      end

      def test_plain_pdf_and_png_ignore_optional_mainz
        producer(status: 1)
        _out, warning = capture_io do
          Export.call(@svg, @output)
          Export.call(@svg, File.join(@directory, "drawing.png"), style: @style)
        end
        assert_empty(warning)
        assert_equal(1, HexaPDF::Document.open(@output).pages.count)
        assert(File.binread(File.join(@directory, "drawing.png")).start_with?("\x89PNG".b))
      end

      def test_fingerprint_tracks_installation_and_binary_changes
        refute(Mainz.available?)
        assert_nil(Mainz.fingerprint)
        producer
        assert(Mainz.available?)
        fingerprint = Mainz.fingerprint
        producer(status: 1)
        refute_equal(fingerprint, Mainz.fingerprint)
      end

      def test_fingerprint_rejects_invalid_runtime_reports
        ["[]", "{}", '{"contract":2}', "invalid"].each do |report|
          File.write(@program, "#!#{RbConfig.ruby}\nputs #{report.dump}\n")
          File.chmod(0o755, @program)
          assert_raises(Mainz::Error) { Mainz.fingerprint }
        end
      end

      def test_parallel_exports_keep_source_and_staging_separate
        producer
        outputs = 4.times.map do |index|
          Thread.new do
            path = File.join(@directory, "drawing-#{index}.pdf")
            Export.call(@svg.sub('id="ink"', "id=\"ink-#{index}\""), path, style: @style)
            JSON.parse(File.read(path).lines.drop(1).join).fetch("svg")
          end
        end.map(&:value)
        outputs.each_with_index { |source, index| assert_includes(source, "id=\"ink-#{index}\"") }
        refute(Dir.children(@directory).any? { it.start_with?(".sevgi-mainz-") })
      end

      private

      def producer(status: 0, signal: nil)
        interruption = signal ? "Process.kill(#{signal.dump}, Process.pid)" : ""
        File.write(@program, <<~RUBY)
          #!#{RbConfig.ruby}
          require "json"
          if ARGV == ["--version"]
            puts JSON.generate(contract: 1)
            exit 0
          end
          command, source, *arguments = ARGV
          abort "unexpected command" unless command == "produce"
          options = arguments.each_slice(2).to_h
          output = options.fetch("--output")
          File.write(output, "%PDF-1.7\n" + JSON.generate(
            svg: File.read(source), style: JSON.parse(File.read(options.fetch("--declaration"))), options: options))
          warn "unsupported preparation" unless #{status}.zero?
          #{interruption}
          exit #{status}
        RUBY
        File.chmod(0o755, @program)
      end
    end
  end
end
