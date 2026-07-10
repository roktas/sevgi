# frozen_string_literal: true

require_relative "../test_helper"

require "sevgi/binaries/rake"
require "tmpdir"

module Sevgi
  module Binaries
    class RakeTest < Minitest::Test
      def test_sevgi_executes_script_with_arguments
        Dir.mktmpdir do |dir|
          file = File.join(dir, "drawing.sevgi")
          File.write(
            file,
            <<~RUBY
              raise "bad ARGA" unless ARGA == ["left"]
              raise "bad ARGH" unless ARGH == {name: "grid"}

              SVG do
                text ARGH.fetch(:name)
              end
            RUBY
          )

          result = Object.new.extend(::FileUtils).sevgi(File.join(dir, "drawing"), "left", name: "grid")

          refute(result.error?, result.error&.message)
          assert_includes(result.recent.(), ">grid<")
        end
      end
    end
  end
end
