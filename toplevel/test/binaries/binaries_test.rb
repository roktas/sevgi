# frozen_string_literal: true

require_relative "../test_helper"

require "fileutils"
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

      GemSpec = Data.define(:full_gem_path, :metadata)

      def test_call_uses_main_mode_by_default
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, main:|
            calls << [file, require, main]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["script.sevgi"]) }
        end

        assert_equal([["script.sevgi", nil, true]], calls)
      end

      def test_call_nomain_uses_isolated_mode
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, main:|
            calls << [file, require, main]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["-n", "script.sevgi"]) }
        end

        assert_equal([["script.sevgi", nil, false]], calls)
      end

      def test_call_nomain_long_option_matches_short_option
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, main:|
            calls << [file, require, main]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["--nomain", "script.sevgi"]) }
        end

        assert_equal([["script.sevgi", nil, false]], calls)
      end

      def test_call_forwards_required_library
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, main:|
            calls << [file, require, main]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["-r", "json", "script.sevgi"]) }
        end

        assert_equal([["script.sevgi", "json", true]], calls)
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

      def test_help_lists_options
        out, _err = capture_io { Sevgi.(["--help"]) }

        assert_match(/-n, --nomain/, out)
        assert_match(/--skill/, out)
      end

      def test_call_skill_reports_the_matching_appendix_skill
        with_skill do |root, skill|
          spec = GemSpec.new(root, {"sevgi_skill_path" => "agents/skills/sevgi"})
          requests = []

          ::Gem::Specification.stub(
            :find_by_name,
            proc { |name, requirement|
              requests << [name, requirement]
              spec
            }
          ) do
            with_env("SEVGI_SKILL", nil) do
              out, err = capture_io { Sevgi.(["--skill"]) }

              assert_equal("#{skill}\n", out)
              assert_empty(err)
            end
          end

          assert_equal([["sevgi-appendix", "= #{::Sevgi::VERSION}"]], requests)
        end
      end

      def test_call_skill_preserves_a_packager_path
        with_skill do |root, skill|
          stable = ::File.join(root, "stable")
          ::File.symlink(skill, stable)
          spec = GemSpec.new(root, {"sevgi_skill_path" => "agents/skills/sevgi"})

          ::Gem::Specification.stub(:find_by_name, spec) do
            with_env("SEVGI_SKILL", stable) do
              out, err = capture_io { Sevgi.(["--skill"]) }

              assert_equal("#{stable}\n", out)
              assert_empty(err)
            end
          end
        end
      end

      def test_call_skill_requires_a_matching_appendix_before_the_packager_path
        with_skill do |_root, skill|
          error = ::Gem::MissingSpecError.new("sevgi-appendix", "= #{::Sevgi::VERSION}")

          ::Gem::Specification.stub(:find_by_name, proc { raise error }) do
            with_env("SEVGI_SKILL", skill) do
              out, err = capture_io do
                exit = assert_raises(SystemExit) { Sevgi.(["--skill"]) }

                assert_equal(1, exit.status)
              end

              assert_empty(out)
              assert_equal("sevgi-appendix #{::Sevgi::VERSION} is not installed.\n", err)
              refute_match(/Usage:/, err)
            end
          end
        end
      end

      def test_call_skill_rejects_an_incomplete_appendix
        Dir.mktmpdir do |root|
          spec = GemSpec.new(root, {"sevgi_skill_path" => "agents/skills/sevgi"})

          ::Gem::Specification.stub(:find_by_name, spec) do
            with_env("SEVGI_SKILL", nil) do
              out, err = capture_io do
                exit = assert_raises(SystemExit) { Sevgi.(["--skill"]) }

                assert_equal(1, exit.status)
              end

              assert_empty(out)
              assert_match(/Sevgi skill is unavailable/, err)
              refute_match(/Usage:/, err)
            end
          end
        end
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

      def test_executable_accepts_empty_script
        with_script("") do |file|
          out, err, status = run_sevgi(file)

          assert_equal(0, status.exitstatus)
          assert_empty(out)
          assert_empty(err)
        end
      end

      def test_executable_accepts_dash_prefixed_file_after_separator
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "-drawing.sevgi"), "")

          out, err, status = run_sevgi("--", "-drawing.sevgi", chdir: dir)

          assert_predicate(status, :success?)
          assert_empty(out)
          assert_empty(err)
        end
      end

      def test_executable_rejects_invalid_argv_grammar
        [
          [["-r"], /Option requires a library: -r/],
          [["--require"], /Option requires a library: --require/],
          [%w[first.sevgi second.sevgi], /Unexpected argument: second\.sevgi/]
        ].each do |args, message|
          out, err, status = run_sevgi(*args)

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_match(message, err)
          assert_match(/Usage: sevgi \[options\.\.\.\] \[--\] <Sevgi file>/, err)
        end
      end

      def test_executable_reports_missing_require_for_empty_script
        with_script("") do |file|
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

      def run_sevgi(*args, env: {}, chdir: nil)
        lib = ::File.expand_path("../../lib", __dir__)
        bin = ::File.expand_path("../../bin/sevgi", __dir__)
        rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(::File::PATH_SEPARATOR)
        options = chdir ? {chdir:} : {}

        ::Open3.capture3(
          {"RUBYLIB" => rubylib, "SEVGI_VOMIT" => nil}.merge(env),
          ::RbConfig.ruby,
          bin,
          *args,
          **options
        )
      end

      def with_env(name, value)
        present = ENV.key?(name)
        previous = ENV.fetch(name, nil)
        value.nil? ? ENV.delete(name) : ENV[name] = value
        yield
      ensure
        present ? ENV[name] = previous : ENV.delete(name)
      end

      def with_skill
        Dir.mktmpdir do |root|
          skill = ::File.join(root, "agents/skills/sevgi")
          ::FileUtils.mkdir_p(skill)
          ::File.write(::File.join(skill, "SKILL.md"), "# Sevgi\n")
          yield(root, skill)
        end
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
