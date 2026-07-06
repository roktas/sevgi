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

          error = assert_raises(RuntimeError) { Function.executable!("missing-tool --version") }

          assert_equal("Missing executable: missing-tool", error.message)
        end

        def test_executable_bang_rejects_blank_program
          error = assert_raises(RuntimeError) { Function.executable!("") }

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
