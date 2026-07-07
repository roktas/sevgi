# frozen_string_literal: true

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
    end
  end
end
