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

      def test_call_uses_isolated_mode
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, main:, as: nil|
            assert_nil(as)
            calls << [file, require, main]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["script.sevgi"]) }
        end

        assert_equal([["script.sevgi", nil, false]], calls)
      end

      def test_call_forwards_required_library
        calls = []

        ::Sevgi.stub(
          :execute_file,
          proc { |file, require:, main:, as: nil|
            assert_nil(as)
            calls << [file, require, main]
            Result.new(nil)
          }
        ) do
          _out, _err = capture_io { Sevgi.(["-r", "json", "script.sevgi"]) }
        end

        assert_equal([["script.sevgi", "json", false]], calls)
      end

      def test_call_reports_load_stack_for_script_error
        fixture = "test/fixtures/executor/test_load_nested.sevgi"

        out, err = capture_io do
          error = assert_raises(SystemExit) { Sevgi.([fixture]) }

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

        assert_match(/--as NAME/, out)
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

      def test_executable_as_preserves_missing_file_error_policy
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "missing.sevgi")
          out, err, status = run_sevgi("--as", "badge", file)

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_match(/No such file or directory/, err)
          refute_raw_error(err)
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

      def test_executable_reads_stdin_when_file_is_omitted_or_dash
        source = <<~SEVGI
          SVG :minimal do
            circle r: 4
          end.Out
        SEVGI

        [[], ["-"]].each do |args|
          out, err, status = run_sevgi(*args, stdin_data: source)

          assert_predicate(status, :success?)
          assert_match(%r{<circle r="4"/>}, out)
          assert_empty(err)
        end
      end

      def test_executable_uses_stdin_name_for_implicit_save
        source = "SVG(:minimal) { circle r: 4 }.Save\n"

        Dir.mktmpdir do |dir|
          out, err, status = run_sevgi(chdir: dir, stdin_data: source)

          assert_predicate(status, :success?)
          assert_empty(out)
          assert_empty(err)
          assert_path_exists(::File.join(dir, "output.svg"))
        end
      end

      def test_executable_as_sets_stdin_implicit_output_name
        source = "SVG(:minimal) { circle r: 4 }.Save\n"

        Dir.mktmpdir do |dir|
          out, err, status = run_sevgi("--as", "badge", chdir: dir, stdin_data: source)

          assert_predicate(status, :success?)
          assert_empty(out)
          assert_empty(err)
          assert_path_exists(::File.join(dir, "badge.svg"))
          refute_path_exists(::File.join(dir, "output.svg"))
        end
      end

      def test_executable_as_renames_file_in_its_source_directory
        source = "SVG(:minimal) { circle r: 4 }.Save\n"

        Dir.mktmpdir do |dir|
          input = ::File.join(dir, "drawing.sevgi")
          ::File.write(input, source)

          out, err, status = run_sevgi("--as", "badge", input)

          assert_predicate(status, :success?)
          assert_empty(out)
          assert_empty(err)
          assert_path_exists(::File.join(dir, "badge.svg"))
          refute_path_exists(::File.join(dir, "drawing.svg"))
        end
      end

      def test_executable_as_preserves_load_identity
        Dir.mktmpdir do |dir|
          input = ::File.join(dir, "drawing.sevgi")
          shared = ::File.join(dir, "shared.sevgi")
          ::File.write(input, "Load 'shared'\n")
          ::File.write(shared, "warn 'loaded'\n")

          out, err, status = run_sevgi("--as", "shared", input)

          assert_predicate(status, :success?)
          assert_empty(out)
          assert_equal("loaded\n", err)
        end
      end

      def test_executable_as_does_not_override_explicit_save_default
        source = "SVG(:minimal) { circle r: 4 }.Save default: \"chosen.svg\"\n"

        Dir.mktmpdir do |dir|
          out, err, status = run_sevgi("--as", "badge", chdir: dir, stdin_data: source)

          assert_predicate(status, :success?)
          assert_empty(out)
          assert_empty(err)
          assert_path_exists(::File.join(dir, "chosen.svg"))
          refute_path_exists(::File.join(dir, "badge.svg"))
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
          [["--as"], /Option requires a name: --as/],
          [["--as", "build/badge"], /Option requires a name, not a path: --as/],
          [%w[first.sevgi second.sevgi], /Unexpected argument: second\.sevgi/]
        ].each do |args, message|
          out, err, status = run_sevgi(*args)

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_match(message, err)
          assert_match(/Usage: sevgi \[options\.\.\.\] \[--\] \[Sevgi file\|-\]/, err)
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

      def run_sevgi(*args, env: {}, chdir: nil, stdin_data: "")
        lib = ::File.expand_path("../../lib", __dir__)
        bin = ::File.expand_path("../../bin/sevgi", __dir__)
        rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(::File::PATH_SEPARATOR)
        options = chdir ? {chdir:} : {}

        ::Open3.capture3(
          {"RUBYLIB" => rubylib, "SEVGI_VOMIT" => nil}.merge(env),
          ::RbConfig.ruby,
          bin,
          *args,
          stdin_data:,
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
