# frozen_string_literal: true

require_relative "../test_helper"

require "open3"
require "rbconfig"
require "sevgi/binaries/sevgi"
require "tmpdir"

module Sevgi
  module Binaries
    class SevgiTest < Minitest::Test
      Result = Data.define(:error) do
        def error? = !error.nil?
      end

      def test_call_uses_caller_toplevel_by_default
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, receiver:|
            calls << [file, require, receiver]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["script.sevgi"]) }
        end

        assert_equal([["script.sevgi", nil, TOPLEVEL_BINDING.receiver]], calls)
      end

      def test_call_nomain_uses_isolated_receiver
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, receiver:|
            calls << [file, require, receiver]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["-n", "script.sevgi"]) }
        end

        assert_equal([["script.sevgi", nil, nil]], calls)
      end

      def test_call_nomain_long_option_matches_short_option
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, receiver:|
            calls << [file, require, receiver]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["--nomain", "script.sevgi"]) }
        end

        assert_equal([["script.sevgi", nil, nil]], calls)
      end

      def test_call_forwards_required_library
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, receiver:|
            calls << [file, require, receiver]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["-r", "json", "script.sevgi"]) }
        end

        assert_equal([["script.sevgi", "json", TOPLEVEL_BINDING.receiver]], calls)
      end

      def test_call_reports_load_stack_for_script_error
        fixture = "test/fixtures/executor/test_load_nested.sevgi"

        out, err = capture_io do
          error = assert_raises(SystemExit) { Sevgi.(["-n", fixture]) }

          assert_equal(1, error.status)
        end

        assert_empty(out)
        assert_equal(
          <<~ERR,
            undefined method 'de' for module Sevgi::Main

              test/fixtures/executor/test_load_nested_2.sevgi:3:in 'Sevgi::Executor::Scope#evaluate'
              test/fixtures/executor/test_load_nested_1.sevgi:3:in 'Sevgi::Executor::Scope#evaluate'
              test/fixtures/executor/test_load_nested.sevgi:3:in 'Sevgi::Executor::Scope#evaluate'
          ERR
          err
        )
      end

      def test_help_reports_nomain_short_option
        out, _err = capture_io { Sevgi.(["--help"]) }

        assert_match(/-n, --nomain/, out)
      end

      def test_executable_reports_missing_file
        Dir.mktmpdir do |dir|
          out, err, status = run_sevgi(::File.join(dir, "missing.sevgi"))

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_match(/No such file or directory/, err)
          refute_raw_error(err)
        end
      end

      def test_executable_vomits_missing_file
        Dir.mktmpdir do |dir|
          out, err, status = run_sevgi("-x", ::File.join(dir, "missing.sevgi"))

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_raw_error(err)
          assert_match(/No such file or directory/, err)
        end
      end

      def test_executable_reports_unreadable_file
        with_unreadable_script do |file|
          out, err, status = run_sevgi(file)
          skip("filesystem allowed unreadable fixture") if status.success?

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_match(/Permission denied/, err)
          refute_raw_error(err)
        end
      end

      def test_executable_vomits_unreadable_file
        with_unreadable_script do |file|
          out, err, status = run_sevgi(file, env: {"SEVGI_VOMIT" => "t"})
          skip("filesystem allowed unreadable fixture") if status.success?

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_raw_error(err)
          assert_match(/Permission denied/, err)
        end
      end

      def test_executable_reports_missing_require
        with_script("1\n") do |file|
          out, err, status = run_sevgi("-r", "sevgi_missing_test_library", file)

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_match(/sevgi_missing_test_library/, err)
          refute_raw_error(err)
        end
      end

      def test_executable_vomits_missing_require
        with_script("1\n") do |file|
          out, err, status = run_sevgi("-x", "-r", "sevgi_missing_test_library", file)

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_raw_error(err)
          assert_match(/sevgi_missing_test_library/, err)
        end
      end

      def test_executable_preserves_exit_status_policy
        with_script("exit(7)\n") do |file|
          _out, _err, normal = run_sevgi(file)
          _out, _err, exception = run_sevgi("-x", file)

          assert_equal(1, normal.exitstatus)
          assert_equal(1, exception.exitstatus)
        end
      end

      private

      def assert_raw_error(err)
        assert_match(/Sevgi::Executor::Error/, err)
        assert_match(%r{toplevel/lib|bin/sevgi}, err)
      end

      def refute_raw_error(err)
        refute_match(/Sevgi::Executor::Error/, err)
        refute_match(%r{toplevel/lib|bin/sevgi|Traceback}, err)
      end

      def run_sevgi(*args, env: {})
        lib = ::File.expand_path("../../lib", __dir__)
        bin = ::File.expand_path("../../bin/sevgi", __dir__)
        rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(::File::PATH_SEPARATOR)

        ::Open3.capture3(
          {"RUBYLIB" => rubylib, "SEVGI_VOMIT" => nil}.merge(env),
          ::RbConfig.ruby,
          bin,
          *args
        )
      end

      def with_script(source)
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "script.sevgi")
          ::File.write(file, source)
          yield(file)
        end
      end

      def with_unreadable_script
        with_script("1\n") do |file|
          old = ::File.stat(file).mode
          ::File.chmod(0, file)
          yield(file)
        ensure
          ::File.chmod(old, file) if old
        end
      end
    end
  end
end
