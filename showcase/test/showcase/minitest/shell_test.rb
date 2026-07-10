# frozen_string_literal: true

require "rbconfig"
require "timeout"
require "tmpdir"

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

      def test_run_accepts_block_input
        result = Shell.run(ruby, "-e", "puts STDIN.read") do
          write("showcase")
        end

        assert_equal(["showcase"], result.out)
      end

      def test_run_closes_stdin_without_input
        result = Timeout.timeout(2) do
          Shell.run(ruby, "-e", "puts STDIN.read.empty?")
        end

        assert_equal(["true"], result.out)
      end

      def test_run_cleans_up_when_input_block_raises
        Dir.mktmpdir do |dir|
          pidfile = File.join(dir, "pid")
          script = <<~RUBY
            File.write(#{pidfile.inspect}, Process.pid)
            STDIN.read
          RUBY
          wait = method(:wait_for_file)

          Timeout.timeout(5) do
            assert_raises(RuntimeError) do
              Shell.run(ruby, "-e", script) do
                wait.call(pidfile)
                raise "input failed"
              end
            end
          end

          assert_process_exited(Integer(File.read(pidfile)))
        end
      end

      private

      def assert_process_exited(pid)
        Timeout.timeout(2) do
          loop do
            Process.kill(0, pid)
            sleep(0.05)
          rescue Errno::ESRCH
            break
          end
        end
      end

      def ruby = RbConfig.ruby

      def wait_for_file(path)
        Timeout.timeout(2) do
          sleep(0.01) until File.exist?(path)
        end
      end
    end
  end
end
