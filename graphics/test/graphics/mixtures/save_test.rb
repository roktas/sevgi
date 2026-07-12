# frozen_string_literal: true

require "tmpdir"

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class SaveTest < Minitest::Test
        def test_out_writes_rendered_svg_to_stdout
          out, err = capture_io { SVG(:minimal) { rect(id: "one") }.Out() }

          assert_equal("<svg>\n  <rect id=\"one\"/>\n</svg>\n", out)
          assert_empty(err)
        end

        def test_save_returns_expanded_path_only_when_changed
          Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
              path = File.join("nested", "out.svg")
              expected = File.expand_path(path)
              document = SVG(:minimal) { rect(id: "one") }

              result = document.Save(path)

              [
                expected,
                result,
                "<svg>\n  <rect id=\"one\"/>\n</svg>\n",
                File.read(path)
              ].each_slice(2) { |wanted, actual| assert_equal(wanted, actual) }

              assert_nil(document.Save(path))
            end
          end
        end

        def test_save_backs_up_only_changed_destinations
          Dir.mktmpdir do |dir|
            path = File.join(dir, "out.svg")
            backup = "#{path}.bak"
            File.write(path, "old\n")

            SVG(:minimal) { rect(id: "new") }.Save(path, backup_suffix: ".bak")

            [
              "old\n",
              File.read(backup),
              "<svg>\n  <rect id=\"new\"/>\n</svg>\n",
              File.read(path)
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }

            File.write(backup, "keep\n")
            result = SVG(:minimal) { rect(id: "ignored") }.Save(path, backup_suffix: ".bak") { "same" }

            assert_nil(result)
            assert_equal("keep\n", File.read(backup))
            assert_equal("<svg>\n  <rect id=\"new\"/>\n</svg>\n", File.read(path))
          end
        end

        def test_save_forwards_render_options
          Dir.mktmpdir do |dir|
            path = File.join(dir, "out.svg")

            SVG(:minimal) { rect(id: "one") }.Save(path, indent: "")

            assert_equal("<svg>\n<rect id=\"one\"/>\n</svg>\n", File.read(path))
          end
        end

        def test_save_uses_default_name_for_directory
          Dir.mktmpdir do |dir|
            result = SVG(:minimal).Save(dir)
            expected = File.join(dir, "save_test.svg")

            assert_equal(expected, result)
            assert_path_exists(expected)
          end
        end

        def test_write_writes_rendered_svg_to_path
          Dir.mktmpdir do |dir|
            path = File.join(dir, "out.svg")

            result = SVG(:minimal) { rect(id: "one") }.Write(path)

            [
              path,
              result,
              "<svg>\n  <rect id=\"one\"/>\n</svg>\n",
              File.read(path)
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end
        end

        def test_writers_normalize_paths_and_create_parents
          Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
              document = SVG(:minimal) { rect(id: "one") }
              paths = [
                [-> (path) { document.Save(path) }, Pathname("save/out.svg")],
                [-> (path) { document.Write(path) }, Pathname("write/out.svg")]
              ]

              paths.each do |writer, path|
                expected = File.expand_path(path)

                assert_equal(expected, writer.call(path))
                assert_path_exists(expected)
                assert_nil(writer.call(path))
              end
            end
          end
        end

        def test_writers_propagate_file_failures
          Dir.mktmpdir do |dir|
            blocker = File.join(dir, "blocker")
            File.write(blocker, "file")
            path = File.join(blocker, "out.svg")
            document = SVG(:minimal)

            assert_raises(SystemCallError) { document.Save(path) }
            assert_raises(SystemCallError) { document.Write(path) }
          end
        end
      end
    end
  end
end
