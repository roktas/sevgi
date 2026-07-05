# frozen_string_literal: true

require_relative "../test_helper"

require "sevgi/binaries/sevgi"

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
    end
  end
end
