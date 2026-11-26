# frozen_string_literal: true

require "open3"
require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Showcase
    class PassiveTest < Minitest::Test
      def test_save_redirects_output
        Dir.mktmpdir do |directory|
          destination = File.join(directory, "badge.svg")
          script = File.join(directory, "badge.sevgi")
          File.write(
            script,
            <<~SEVGI
              SVG { rect width: 1, height: 1 }.Save default: #{destination.dump}, backup_suffix: ".bak"
            SEVGI
          )
          F.sh!("sevgi", script)
          expected = File.read(destination)
          File.unlink(destination)
          output, error, status = Open3.capture3("sevgi", "-r", "sevgi/showcase/passive", script)

          assert(status.success?, error)
          assert_equal(expected, output)
          refute_path_exists(destination)
        end
      end
    end
  end
end
