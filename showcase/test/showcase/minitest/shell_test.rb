# frozen_string_literal: true

require "open3"
require "rbconfig"
require "timeout"
require "tmpdir"

require_relative "../../test_helper"

require "sevgi/showcase/minitest"

module Sevgi
  module Showcase
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

        def test_run_sigint_second_interrupt_kills
          signals = []
          runner = Shell::Runner.new

          Process.stub(:kill, -> (signal, pid) { signals << [signal, pid] }) do
            capture_io do
              runner.send(:handle_sigint, 12_345)
              runner.send(:handle_sigint, 12_345)
            end
          end

          assert_equal([["TERM", 12_345], ["KILL", 12_345]], signals)
        end

        def test_run_real_sigint_escalates_without_trap_errors
          Dir.mktmpdir do |dir|
            completed = false
            ready = File.join(dir, "ready")
            term = File.join(dir, "term")
            child = <<~RUBY
              Signal.trap("TERM") { File.write(#{term.inspect}, "TERM") }
              File.write(#{ready.inspect}, Process.pid)
              loop { sleep(1) }
            RUBY
            script = <<~RUBY
              require "rbconfig"
              require "sevgi/showcase/minitest"
              baseline = Thread.list.count
              restored = false
              Signal.trap("INT") { restored = true }
              test = Sevgi::Showcase.const_get(:Test, false)
              result = test::Shell.run(RbConfig.ruby, "-e", #{child.inspect})
              Process.kill("INT", Process.pid)
              puts(result.exit_code.inspect, restored.inspect, (Thread.list.count == baseline).inspect)
            RUBY

            out, err, status = run_signal_probe(script, ready) do |pid|
              Process.kill("INT", pid)
              wait_for_file(term)
              Process.kill("INT", pid)
            end

            completed = status.success?

            assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
            assert_equal(%w[nil true true], out.lines(chomp: true))
            assert_includes(err, "SIGINT received.")
            assert_includes(err, "SIGINT received again. Force quitting...")
            refute_includes(err, "trap context")
          ensure
            stop_probe(File.read(ready).to_i) if !completed && ready && File.exist?(ready)
          end
        end

        def test_run_shares_process_signal_state
          function = ::Sevgi::Function::Shell.const_get(:Signals, false)
          showcase = Shell.const_get(:Signals, false)

          assert_same(function, showcase)
        end

        def test_run_coordinates_overlapping_signal_handlers
          registry = Shell.const_get(:Signals, false)
          baseline = proc { }
          previous = Signal.trap("INT", baseline)
          first = Shell::Runner.new
          second = Shell::Runner.new
          signals = []

          Process.stub(:kill, -> (signal, pid) { signals << [signal, pid] }) do
            registry.register(first, 1)
            registry.register(second, 2)
            capture_io do
              registry.send(:dispatch)
              registry.send(:dispatch)
            end

            registry.unregister(first)

            current = Signal.trap("INT", "DEFAULT")
            refute_same(baseline, current)
            Signal.trap("INT", current)

            registry.unregister(second)
            restored = Signal.trap("INT", "DEFAULT")
            assert_same(baseline, restored)
          end

          assert_equal(
            [["TERM", 1], ["TERM", 2], ["KILL", 1], ["KILL", 2]],
            signals
          )
        ensure
          registry&.unregister(first) if first
          registry&.unregister(second) if second
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

        def run_signal_probe(script, ready)
          lib = File.expand_path("../../../lib", __dir__)
          rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(File::PATH_SEPARATOR)

          Open3.popen3({"RUBYLIB" => rubylib}, RbConfig.ruby, "-e", script) do |stdin, stdout, stderr, thread|
            stdin.close
            wait_for_file(ready)
            yield(thread.pid)
            status = Timeout.timeout(3) { thread.value }

            return [stdout.read, stderr.read, status]
          ensure
            stop_probe(thread.pid) if thread&.alive?
          end
        end

        def ruby = RbConfig.ruby

        def stop_probe(pid)
          Process.kill("KILL", pid)
        rescue Errno::ESRCH
          nil
        end

        def wait_for_file(path)
          Timeout.timeout(2) do
            sleep(0.01) until File.exist?(path)
          end
        end
      end
    end
  end
end
