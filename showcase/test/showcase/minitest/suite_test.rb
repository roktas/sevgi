# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require_relative "../../test_helper"

require "sevgi/showcase/minitest"

module Sevgi
  module Showcase
    module Test
      class SuiteTest < Minitest::Test
        def test_suite_filters_hidden_and_library_scripts
          Dir.mktmpdir do |dir|
            executable(File.join(dir, "valid", "one.sevgi"))
            executable(File.join(dir, "_hidden", "two.sevgi"))
            executable(File.join(dir, "lib", "three.sevgi"))
            executable(File.join(dir, "library", "four.sevgi"))

            suite = Suite.new(dir)

            assert_equal(["valid"], suite.suites)
            assert_equal(["one"], suite.valids.map(&:name))
          end
        end

        def test_suite_splits_valid_and_non_valid_scripts
          Dir.mktmpdir do |dir|
            executable(File.join(dir, "valid", "one.sevgi"))
            executable(File.join(dir, "gotcha", "two.sevgi"))

            suite = Suite.new(dir)

            [
              %w[gotcha valid],
              suite.suites.sort,
              ["one"],
              suite.valids.map(&:name),
              ["two"],
              suite.non_valids.map(&:name),
              suite.valids,
              suite.to_a
            ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
          end
        end

        private

        def executable(file)
          FileUtils.mkdir_p(File.dirname(file))
          File.write(file, "")
          File.chmod(0o755, file)
          file
        end
      end
    end
  end
end
