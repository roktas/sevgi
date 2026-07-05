# frozen_string_literal: true

require "tmpdir"

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class SaveTest < Minitest::Test
        def test_save_writes_rendered_svg
          Dir.mktmpdir do |dir|
            path = File.join(dir, "nested", "out.svg")

            result = SVG(:minimal) { rect(id: "one") }.Save(path)

            [
              path,
              result,
              "<svg>\n  <rect id=\"one\"/>\n</svg>\n",
              File.read(path)
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end
        end

        def test_save_creates_backup_before_overwriting
          Dir.mktmpdir do |dir|
            path = File.join(dir, "out.svg")
            File.write(path, "old\n")

            SVG(:minimal) { rect(id: "new") }.Save(path, backup_suffix: ".bak")

            [
              "old\n",
              File.read("#{path}.bak"),
              "<svg>\n  <rect id=\"new\"/>\n</svg>\n",
              File.read(path)
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end
        end
      end
    end
  end
end
