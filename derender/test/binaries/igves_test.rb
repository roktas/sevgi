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
    end
  end
end
