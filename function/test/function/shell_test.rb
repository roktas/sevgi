# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "timeout"
require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Function
    module Shell
      class ShellTest < Minitest::Test
        def teardown
          clear_executable_cache
        end

        def test_executable_caches_positive_result
          with_executable("cached-tool") do |path|
            assert(Function.executable?("cached-tool"))

            FileUtils.rm(path)

            assert(Function.executable?("cached-tool"))
          end
        end

        def test_executable_returns_false_without_path
          path = ENV.fetch("PATH", nil)
          ENV.delete("PATH")
          clear_executable_cache

          refute(Function.executable?("missing-tool"))
        ensure
          ENV["PATH"] = path
        end

        def test_executable_rejects_blank_program
          refute(Function.executable?(nil))
          refute(Function.executable?(""))
        end

        def test_executable_caches_negative_result
          Dir.mktmpdir do |dir|
            with_path(dir) do
              clear_executable_cache

              refute(Function.executable?("missing-tool"))

              path = ::File.join(dir, "missing-tool")
              ::File.write(path, "#!/bin/sh\n")
              FileUtils.chmod("+x", path)

              refute(Function.executable?("missing-tool"))
            end
          end
        end

        def test_executable_bang_raises_for_missing_program
          clear_executable_cache

          error = assert_raises(Error) { Function.executable!("missing-tool --version") }

          assert_equal("Missing executable: missing-tool", error.message)
        end

        def test_executable_bang_rejects_blank_program
          error = assert_raises(Error) { Function.executable!("") }

          assert_equal("Missing executable: ", error.message)
        end

        def test_sh_bang_checks_executable_from_first_argument
          checked = nil
          ran = nil
          result = Result.new(["tool", "--version"], [], [], 0)

          Function.stub(:executable!, -> (*args) { checked = args }) do
            Function.stub(
              :sh,
              -> (*args) {
                ran = args
                result
              }
            ) do
              assert_same(result, Function.sh!("tool", "--version"))
            end
          end

          assert_equal(["tool", "--version"], checked)
          assert_equal(["tool", "--version"], ran)
        end

        def test_sh_bang_raises_for_failed_command
          error = nil
          ruby = ::File.basename(RbConfig.ruby)
          capture_io do
            error = assert_raises(Error) do
              Function.sh!(ruby, "-e", "$stderr.puts \"bad\"; exit 7")
            end
          end

          assert_equal("Command failed: #{ruby} -e $stderr.puts \"bad\"; exit 7", error.message)
        end

        def test_sh_returns_dummy_result_without_arguments
          result = Function.sh

          assert(result.ok?)
          assert_empty(result.args)
          assert_empty(result.out)
          assert_empty(result.err)
        end

        def test_sh_closes_stdin_without_input
          result = Timeout.timeout(2) do
            Function.sh(RbConfig.ruby, "-e", "puts STDIN.read.empty?")
          end

          assert_equal("true", result.out)
        end

        def test_sh_captures_large_stderr_without_blocking
          script = "$stderr.write('x' * 200_000); $stdout.puts 'done'"

          result = Timeout.timeout(3) do
            Function.sh(RbConfig.ruby, "-e", script)
          end

          assert_equal("done", result.outline)
          assert_equal(200_000, result.err.size)
        end

        def test_sh_handles_full_duplex_large_io
          size = 2 * 1024 * 1024
          script = <<~RUBY
            STDOUT.write("x" * #{size})
            STDOUT.flush
            input = STDIN.read
            STDERR.write(input.bytesize.to_s)
          RUBY

          result = Timeout.timeout(5) do
            Function.sh(RbConfig.ruby, "-e", script) { "y" * size }
          end

          assert_equal(size, result.out.bytesize)
          assert_equal(size.to_s, result.err)
        end

        def test_sh_restores_sigint_handler
          previous = Signal.trap("INT", "DEFAULT")
          handler = proc { }
          Signal.trap("INT", handler)

          Function.sh(RbConfig.ruby, "-e", "exit")
          current = Signal.trap("INT", previous)

          assert_same(handler, current)
        ensure
          Signal.trap("INT", previous) if previous
        end

        def test_sh_cleans_up_when_input_block_raises
          Dir.mktmpdir do |dir|
            pidfile = ::File.join(dir, "pid")
            script = <<~RUBY
              File.write(#{pidfile.inspect}, Process.pid)
              STDIN.read
            RUBY
            previous = Signal.trap("INT", "DEFAULT")
            handler = proc { }
            Signal.trap("INT", handler)

            Timeout.timeout(5) do
              assert_raises(RuntimeError) do
                Function.sh(RbConfig.ruby, "-e", script) do
                  wait_for_file(pidfile)
                  raise "input failed"
                end
              end
            end

            current = Signal.trap("INT", previous)

            assert_same(handler, current)
            assert_process_exited(Integer(::File.read(pidfile)))
          ensure
            Signal.trap("INT", previous) if previous
          end
        end

        def test_sh_sigint_second_interrupt_kills
          signals = []
          runner = Runner.new

          Process.stub(:kill, -> (signal, pid) { signals << [signal, pid] }) do
            capture_io do
              runner.send(:handle_sigint, 12_345)
              runner.send(:handle_sigint, 12_345)
            end
          end

          assert_equal([["TERM", 12_345], ["KILL", 12_345]], signals)
        end

        def test_sh_writes_block_input_once
          calls = 0

          result = Function.sh(RbConfig.ruby, "-e", "puts STDIN.read") do
            calls += 1
            "input#{calls}"
          end

          assert_equal(1, calls)
          assert_equal("input1", result.out)
        end

        private

        def assert_process_exited(pid)
          Timeout.timeout(2) do
            loop do
              ::Process.kill(0, pid)
              sleep(0.05)
            rescue Errno::ESRCH
              break
            end
          end
        end

        def wait_for_file(path)
          Timeout.timeout(2) do
            sleep(0.01) until ::File.exist?(path)
          end
        end

        def clear_executable_cache
          return unless Function.instance_variable_defined?(:@executable_cache)

          Function.remove_instance_variable(:@executable_cache)
        end

        def with_executable(program)
          Dir.mktmpdir do |dir|
            path = ::File.join(dir, program)
            ::File.write(path, "#!/bin/sh\n")
            FileUtils.chmod("+x", path)

            with_path(dir) do
              clear_executable_cache
              yield path
            end
          end
        end

        def with_path(dir)
          path = ENV.fetch("PATH", nil)
          ENV["PATH"] = [dir, path].join(::File::PATH_SEPARATOR)
          yield
        ensure
          ENV["PATH"] = path
        end
      end
    end
  end
end
