# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Function
    class LocateTest < Minitest::Test
      def test_locate_finds_file_upward
        ::Dir.mktmpdir do |dir|
          start = ::File.join(dir, "a", "b")
          ::FileUtils.mkdir_p(start)
          file = ::File.join(dir, "target.sevgi")
          ::File.write(file, "")

          location = Function.locate("target", start)

          assert_instance_of(Function::Location, location)
          assert_equal(file, location.file)
          assert_equal("target.sevgi", location.slug)
          assert_equal(dir, location.dir)
        end
      end

      def test_locate_raises_when_missing
        ::Dir.mktmpdir do |dir|
          error = assert_raises(Error) { Function.locate("missing", dir) }

          assert_equal("Cannot load a file matching: missing", error.message)
        end
      end

      def test_locate_respects_excluded_file
        ::Dir.mktmpdir do |dir|
          start = ::File.join(dir, "child")
          ::FileUtils.mkdir_p(start)

          parent = ::File.join(dir, "shared.sevgi")
          child = ::File.join(start, "shared.sevgi")
          ::File.write(parent, "")
          ::File.write(child, "")

          location = Function.locate("shared", start, exclude: child)

          assert_equal(parent, location.file)
          assert_equal(dir, location.dir)
        end
      end

      def test_locate_restores_working_directory
        origin = ::Dir.pwd

        ::Dir.mktmpdir do |dir|
          assert_raises(Error) { Function.locate("missing", dir) }
        end

        assert_equal(origin, ::Dir.pwd)
      end
    end
  end
end
