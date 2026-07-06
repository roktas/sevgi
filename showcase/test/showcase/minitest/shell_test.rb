# frozen_string_literal: true

require "rbconfig"
require "timeout"

require_relative "../../test_helper"

require "sevgi/showcase"

module Sevgi
  module Test
    class ShellTest < Minitest::Test
      def test_run_captures_output_and_status
        result = Shell.run(ruby, "-e", "$stdout.puts 'out'; $stderr.puts 'err'; exit 7")

        [
          [ruby, "-e", "$stdout.puts 'out'; $stderr.puts 'err'; exit 7"],
          result.args,
          ["out"],
          result.out,
          ["err"],
          result.err,
          7,
          result.exit_code,
          false,
          result.ok?,
          true,
          result.notok?,
          "out",
          result.outline,
          "out",
          result.to_s
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_run_restores_sigint_handler
        handler = proc { }
        previous = Signal.trap("INT", handler)

        result = Shell.run(ruby, "-e", "puts 'ok'")
        restored = Signal.trap("INT", "DEFAULT")

        assert(result.ok?)
        assert_same(handler, restored)
      ensure
        Signal.trap("INT", previous) if previous
      end

      def test_run_captures_large_stderr_without_blocking
        script = "$stderr.write('x' * 200_000); $stdout.puts 'done'"

        result = Timeout.timeout(3) do
          Shell.run(ruby, "-e", script)
        end

        assert_equal("done", result.outline)
        assert_equal(200_000, result.err.join.size)
      end

      private

      def ruby = RbConfig.ruby
    end
  end
end
