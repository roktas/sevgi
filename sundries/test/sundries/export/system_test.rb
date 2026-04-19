# frozen_string_literal: true

require "tmpdir"

require_relative "../../test_helper"

module Sevgi
  module Sundries
    module Export
      class SystemTest < Minitest::Test
        def test_a5ona4_runs_pdfcpu_nup
          result = capture_sh do
            Export.a5ona4("in.pdf", "out.pdf")
          end

          assert_equal [
            "pdfcpu",
            "nup",
            "--",
            "form:A4L, border:off",
            "out.pdf",
            "2",
            "in.pdf",
          ], result[:sh].first
        end

        def test_rsvg_defaults_to_pdf_output
          Dir.mktmpdir do |dir|
            infile = svg_file(dir)

            result = capture_system_commands do
              Export.rsvg(infile)
            end

            assert_equal [
              "rsvg-convert",
              "--format=pdf",
              "--background-color=#ffffff",
              "--output=#{File.join(dir, "input.pdf")}",
              infile,
            ], result[:sh].first
          end
        end

        def test_rsvg_builds_options
          Dir.mktmpdir do |dir|
            infile  = svg_file(dir)
            outfile = File.join(dir, "out.png")

            result = capture_system_commands do
              Export.rsvg(
                infile,
                outfile,
                background: nil,
                height:     30,
                id:         "shape",
                width:      20
              )
            end

            assert_equal [
              "rsvg-convert",
              "--format=png",
              "--width=20",
              "--height=30",
              "--export-id=shape",
              "--output=#{outfile}",
              infile,
            ], result[:sh].first
          end
        end

        def test_rsvg_injects_css_into_temp_input
          Dir.mktmpdir do |dir|
            infile = svg_file(dir)
            args   = nil
            seen   = nil

            F.stub(:sh!, lambda { |*command|
              args = command
              seen = File.read(command.last)
            }) do
              Export.rsvg(infile, css: "rect { fill: red; }")
            end

            refute_equal infile, args.last
            assert_includes seen, "<style>rect { fill: red; }</style>"
          end
        end

        def test_rsvg_rejects_page_keyword
          Dir.mktmpdir do |dir|
            assert_raises(::ArgumentError) do
              Export.rsvg(svg_file(dir), page: 2)
            end
          end
        end

        def test_inkscape_defaults_to_pdf_output
          Dir.mktmpdir do |dir|
            infile  = svg_file(dir)
            outfile = File.join(dir, "out.pdf")

            result = capture_system_commands do
              Export.inkscape(infile, outfile)
            end

            assert_equal [
              "inkscape",
              "--batch-process",
              "--actions=select-by-class:text,object-to-path",
              "--export-type=pdf",
              "--export-background=#ffffff",
              "--export-background-opacity=1",
              "--export-filename=#{outfile}",
              infile,
            ], result[:sh].first
          end
        end

        def test_inkscape_builds_options
          Dir.mktmpdir do |dir|
            infile  = svg_file(dir)
            outfile = File.join(dir, "out.png")

            result = capture_system_commands do
              Export.inkscape(
                infile,
                outfile,
                background: "#000000",
                height:     30,
                id:         "shape",
                page:       2,
                width:      20
              )
            end

            assert_equal [
              "inkscape",
              "--batch-process",
              "--actions=select-by-class:text,object-to-path",
              "--export-type=png",
              "--export-background=#000000",
              "--export-background-opacity=1",
              "--export-width=20",
              "--export-height=30",
              "--export-id=shape",
              "--export-id-only",
              "--export-page=2",
              "--export-filename=#{outfile}",
              infile,
            ], result[:sh].first
          end
        end

        def test_inkscape_injects_css_into_temp_input
          Dir.mktmpdir do |dir|
            infile = svg_file(dir)
            args   = nil
            seen   = nil

            F.stub(:sh!, lambda { |*command|
              args = command
              seen = File.read(command.last)
            }) do
              Export.inkscape(infile, css: "rect { fill: blue; }")
            end

            refute_equal infile, args.last
            assert_includes seen, "<style>rect { fill: blue; }</style>"
          end
        end

        def test_unite_runs_pdfunite
          result = capture_sh do
            Export.unite(%w[a.pdf b.pdf], "out.pdf")
          end

          assert_equal [ "pdfunite", "a.pdf", "b.pdf", "out.pdf" ], result[:sh].first
        end

        private

          def capture_sh
            result = { sh: [] }

            F.stub(:sh!, ->(*args) { result[:sh] << args }) do
              yield
            end

            result
          end

          def capture_system_commands
            result = { sh: [] }

            F.stub(:sh!, ->(*args) { result[:sh] << args }) do
              yield
            end

            result
          end

          def svg_file(dir)
            File.join(dir, "input.svg").tap do |path|
              File.write(path, <<~SVG)
                <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
                  <rect width="10" height="10"/>
                </svg>
              SVG
            end
          end
      end
    end
  end
end
