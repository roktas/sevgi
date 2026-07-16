# frozen_string_literal: true

require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Function
    module File
      class FileTest < Minitest::Test
        def test_changed_applies_filter
          ::Dir.mktmpdir do |dir|
            file = ::File.join(dir, "out.txt")
            ::File.write(file, "hello\n")

            refute(Function.changed?(file, "hello   ", &:strip))
          end
        end

        def test_changed_detects_content_digest
          ::Dir.mktmpdir do |dir|
            file = ::File.join(dir, "out.txt")
            ::File.write(file, "old")

            refute(Function.changed?(file, "old"))
            assert(Function.changed?(file, "new"))
            assert(Function.changed?(::File.join(dir, "missing.txt"), "new"))
          end
        end

        def test_existing_finds_exact_and_qualified_files
          ::Dir.mktmpdir do |dir|
            plain = ::File.join(dir, "image")
            icon = ::File.join(dir, "icon")
            linked = ::File.join(dir, "linked")
            svg = "#{plain}.svg"
            icon_svg = "#{icon}.svg"
            ::File.write(plain, "")
            ::File.write(svg, "")
            ::File.write(icon_svg, "")
            ::File.symlink(plain, linked)

            assert_equal(plain, Function.existing(plain, %w[svg]))
            assert_equal(icon_svg, Function.existing(icon, %w[png svg]))
            assert_equal(linked, Function.existing(linked, []))
            assert_nil(Function.existing(::File.join(dir, "missing"), []))
          end
        end

        def test_existing_rejects_directories
          ::Dir.mktmpdir do |dir|
            exact = ::File.join(dir, "exact")
            qualified = ::File.join(dir, "qualified")
            ::Dir.mkdir(exact)
            ::Dir.mkdir("#{qualified}.svg")

            assert_nil(Function.existing(exact, %w[svg]))
            assert_nil(Function.existing(qualified, %w[svg]))
          end
        end

        def test_existing_map_bang_raises_for_missing_files
          error = assert_raises(ArgumentError) do
            Function.existing_map!("missing", "other", extensions: %w[svg])
          end

          assert_equal("No matching file(s) found: missing, other", error.message)
        end

        def test_out_prints_when_no_path
          out, err = capture_io { Function.out("hello") }

          assert_equal("hello\n", out)
          assert_empty(err)
        end

        def test_out_writes_only_changed_content
          ::Dir.mktmpdir do |dir|
            file = ::File.join(dir, "out.txt")

            assert_equal(file, Function.out("hello", file))
            assert_equal("hello\n", ::File.read(file))
            assert_nil(Function.out("hello\n", file))
          end
        end

        def test_qualify_adds_default_extension
          assert_equal("source.sevgi", Function.qualify("source", "sevgi"))
          assert_equal("source.rb", Function.qualify("source.rb", "sevgi"))
        end

        def test_subext_replaces_and_removes_extensions
          assert_equal("icon.svg", Function.subext("svg", "icon.png"))
          assert_equal("icon", Function.subext("", "icon.png"))
          assert_equal(".", Function.subext("svg", "."))
          assert_equal("..", Function.subext("svg", ".."))
        end

        def test_touch_creates_parent_directories
          ::Dir.mktmpdir do |dir|
            file = ::File.join(dir, "nested", "file.txt")

            assert_equal(file, Function.touch(file))
            assert(::File.exist?(file))
          end
        end
      end
    end
  end
end
