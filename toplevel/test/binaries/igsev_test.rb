# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"

require_relative "../test_helper"

require "sevgi/binaries/igsev"

module Sevgi
  module Binaries
    class IgsevTest < Minitest::Test
      def test_executable_round_trips_svg
        with_svg("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"10\"><circle r=\"4\"/></svg>") do |file|
          out, err, status = run_igsev(file)

          assert_predicate(status, :success?)
          assert_equal(
            <<~SVG,
              <?xml version="1.0" standalone="no"?>
              <svg xmlns="http://www.w3.org/2000/svg" width="10">
                <circle r="4"/>
              </svg>
            SVG
            out
          )
          assert_empty(err)
        end
      end

      def test_executable_omits_repeated_attributes
        source = "<svg xmlns=\"http://www.w3.org/2000/svg\" id=\"root\"><rect id=\"mark\" style=\"fill: red\"/></svg>"
        with_svg(source) do |file|
          out, err, status = run_igsev("--omit", "id", "--omit", "style", file)

          assert_predicate(status, :success?)
          refute_match(/\bid=/, out)
          refute_match(/\bstyle=/, out)
          assert_empty(err)
        end
      end

      def test_executable_accepts_dash_prefixed_file_after_separator
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "-drawing.svg"), "<svg xmlns=\"http://www.w3.org/2000/svg\"/>")

          out, err, status = run_igsev("--", "-drawing.svg", chdir: dir)

          assert_predicate(status, :success?)
          assert_match(/<svg xmlns=/, out)
          assert_empty(err)
        end
      end

      def test_executable_rejects_invalid_argv_grammar
        [
          [["-r"], /Option requires a library: -r/],
          [["--omit"], /No attribute given for --omit/],
          [%w[first.svg second.svg], /Unexpected argument: second\.svg/]
        ].each do |args, message|
          out, err, status = run_igsev(*args)

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_match(message, err)
          assert_match(/Usage: igsev \[options\.\.\.\] \[--\] <SVG file>/, err)
        end
      end

      def test_executable_reports_and_exposes_conversion_errors
        out, err, normal = run_igsev("missing.svg")
        raw_out, raw_err, raw = run_igsev("-x", "missing.svg")

        assert_equal(1, normal.exitstatus)
        assert_empty(out)
        assert_match(/File not found/, err)
        refute_match(/Traceback/, err)

        assert_equal(1, raw.exitstatus)
        assert_empty(raw_out)
        assert_match(/Sevgi::ArgumentError/, raw_err)
      end

      private

      def run_igsev(*args, chdir: nil)
        lib = ::File.expand_path("../../lib", __dir__)
        bin = ::File.expand_path("../../bin/igsev", __dir__)
        rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(::File::PATH_SEPARATOR)
        options = chdir ? {chdir:} : {}

        ::Open3.capture3(
          {"RUBYLIB" => rubylib, "SEVGI_VOMIT" => nil},
          ::RbConfig.ruby,
          bin,
          *args,
          **options
        )
      end

      def with_svg(source)
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "drawing.svg")
          ::File.write(file, source)
          yield(file)
        end
      end
    end
  end
end
