# frozen_string_literal: true

require "tmpdir"

require_relative "../../test_helper"

require "sevgi/showcase"

module Sevgi
  module Test
    class ScriptTest < Minitest::Test
      def test_script_exposes_related_paths
        Dir.mktmpdir do |dir|
          file = executable(File.join(dir, "sample.sevgi"))
          script = Script.new(file)

          [
            File.expand_path(file),
            script.file,
            dir,
            script.dir,
            "sample.sevgi",
            script.file!,
            "sample",
            script.name,
            File.join(dir, "sample.svg"),
            script.svg,
            "sample.svg",
            script.svg!,
            File.join(dir, "sample.yml"),
            script.yml,
            "sample.yml",
            script.yml!,
            File.basename(dir),
            script.suite,
            false,
            script.svg?
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end
      end

      def test_script_rejects_missing_file
        error = assert_raises(ArgumentError) { Script.new("/no/such/file.sevgi") }

        assert_match(/No such file/, error.message)
      end

      def test_script_rejects_non_executable_file
        Dir.mktmpdir do |dir|
          file = File.join(dir, "sample.sevgi")
          File.write(file, "")

          error = assert_raises(ArgumentError) { Script.new(file) }

          assert_match(/Not an executable/, error.message)
        end
      end

      private

      def executable(file)
        File.write(file, "")
        File.chmod(0o755, file)
        file
      end
    end
  end
end
