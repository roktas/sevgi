# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"

require_relative "../test_helper"

require "sevgi/binaries/igves"

module Sevgi
  module Binaries
    class IgvesTest < Minitest::Test
      def test_call_accepts_exception_option
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "drawing.svg")
          ::File.write(file, "<svg id=\"root\"/>")

          out, err = capture_io { Igves.(["-x", file]) }

          assert_equal("SVG id: \"root\"\n", out)
          assert_empty(err)
        end
      end

      def test_call_aborts_on_derender_error
        out, err = capture_io do
          assert_raises(SystemExit) { Igves.(["missing.svg"]) }
        end

        assert_empty(out)
        assert_match(/\bFile not found\b/, err)
      end

      def test_call_exception_option_raises_derender_error
        assert_raises(Sevgi::ArgumentError) { Igves.(["-x", "missing.svg"]) }
      end

      def test_executable_accepts_dash_prefixed_file_after_separator
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "-drawing.svg"), "<svg id=\"root\"/>")

          out, err, status = run_igves("--", "-drawing.svg", chdir: dir)

          assert_predicate(status, :success?)
          assert_equal("SVG id: \"root\"\n", out)
          assert_empty(err)
        end
      end

      def test_executable_rejects_extra_operands
        out, err, status = run_igves("first.svg", "second.svg")

        assert_equal(1, status.exitstatus)
        assert_empty(out)
        assert_match(/Unexpected argument: second\.svg/, err)
        assert_match(/Usage: igves \[options\.\.\.\] \[--\] <SVG file>/, err)
      end

      private

      def run_igves(*args, chdir: nil)
        lib = ::File.expand_path("../../lib", __dir__)
        bin = ::File.expand_path("../../bin/igves", __dir__)
        rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(::File::PATH_SEPARATOR)
        options = chdir ? {chdir:} : {}

        ::Open3.capture3(
          {"RUBYLIB" => rubylib},
          ::RbConfig.ruby,
          bin,
          *args,
          **options
        )
      end
    end
  end
end
