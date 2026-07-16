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

      def test_locate_custom_matcher_receives_absolute_paths
        ::Dir.mktmpdir do |dir|
          start = ::File.join(dir, "child")
          ::FileUtils.mkdir_p(start)
          file = ::File.join(dir, "target.sevgi")
          ::File.write(file, "")

          seen = []
          location = Locate.(["target.sevgi"], start) do |candidate|
            seen << candidate
            ::File.exist?(candidate)
          end

          assert_equal(file, location.file)
          assert(seen.all? { it.start_with?("/") })
        end
      end

      def test_locate_default_rejects_directories
        ::Dir.mktmpdir do |dir|
          candidate = ::File.join(dir, "target.sevgi")
          ::Dir.mkdir(candidate)

          assert_nil(Locate.("target.sevgi", dir))
          assert_equal(candidate, Locate.("target.sevgi", dir, &::File.method(:exist?)).file)
        end
      end

      def test_locator_owns_configuration_and_results
        ::Dir.mktmpdir do |dir|
          start = ::File.join(dir, "child")
          ::FileUtils.mkdir_p(start)
          slug = +"target.sevgi"
          excluded = +::File.join(start, "ignored.sevgi")
          paths = [slug]
          excludes = [excluded]
          locator = Locate.new(paths, start, exclude: excludes)
          matched = nil

          location = locator.call do |candidate|
            matched = candidate
            true
          end

          slug.clear
          excluded.clear
          paths.clear
          excludes.clear
          matched.clear

          assert_equal(["target.sevgi"], locator.paths)
          assert_equal([::File.join(start, "ignored.sevgi")], locator.exclude)
          assert_equal("target.sevgi", location.slug)
          assert_equal(::File.join(start, "target.sevgi"), location.file)
          assert_raises(FrozenError) { locator.paths << "other.sevgi" }
          assert_raises(FrozenError) { location.slug.clear }
          [locator, locator.paths, locator.exclude, location, location.file, location.slug, location.dir].each do |
              value
            |
            assert_predicate(value, :frozen?)
          end
        end
      end

      def test_locator_calls_observe_current_filesystem
        ::Dir.mktmpdir do |dir|
          file = ::File.join(dir, "target.sevgi")
          locator = Locate.new("target.sevgi", dir)

          assert_nil(locator.call)
          ::File.write(file, "")
          location = locator.call
          ::FileUtils.rm(file)

          assert_equal(file, location.file)
          assert_nil(locator.call)
        end
      end

      def test_locate_excludes_candidates_before_custom_matcher
        ::Dir.mktmpdir do |dir|
          start = ::File.join(dir, "child")
          ::FileUtils.mkdir_p(start)
          file = ::File.join(dir, "target.sevgi")
          ::File.write(file, "")
          seen = []

          location = Locate.("target.sevgi", start, exclude: file) do |candidate|
            seen << candidate
            ::File.exist?(candidate)
          end

          assert_nil(location)
          refute_includes(seen, file)
        end
      end

      def test_locate_concurrent_calls_keep_results_and_cwd
        origin = ::Dir.pwd

        ::Dir.mktmpdir do |dir|
          files = prepare_concurrent_tree(dir)
          ready = Queue.new
          release = {a: Queue.new, b: Queue.new}
          results = Queue.new

          a = run_controlled_locate(:a, files, ready, release, results)
          assert_equal(:a, ready.pop)

          b = run_controlled_locate(:b, files, ready, release, results)
          assert_equal(:b, ready.pop)

          release[:a].push(true)
          a.join

          release[:b].push(true)
          b.join

          found = 2.times.to_h { results.pop }

          assert_equal(files[:a][:file], found[:a].file)
          assert_equal(files[:b][:file], found[:b].file)
        end

        assert_equal(origin, ::Dir.pwd)
      end

      def test_locate_restores_working_directory
        origin = ::Dir.pwd

        ::Dir.mktmpdir do |dir|
          assert_raises(Error) { Function.locate("missing", dir) }
        end

        assert_equal(origin, ::Dir.pwd)
      end

      private

      def controlled_match(label, files, ready, release)
        proc do |candidate|
          if ::File.expand_path(candidate) == files[label][:file]
            ready.push(label)
            release[label].pop
          end

          ::File.exist?(candidate)
        end
      end

      def prepare_concurrent_tree(dir)
        %i[a b].to_h do |label|
          parent = ::File.join(dir, label.to_s)
          start = ::File.join(parent, "child")
          file = ::File.join(parent, "#{label}.sevgi")
          ::FileUtils.mkdir_p(start)
          ::File.write(file, "")

          [label, {file:, start:}]
        end
      end

      def run_controlled_locate(label, files, ready, release, results)
        Thread.new do
          location = Locate.(["#{label}.sevgi"], files[label][:start], &controlled_match(label, files, ready, release))
          results.push([label, location])
        end
      end
    end
  end
end
