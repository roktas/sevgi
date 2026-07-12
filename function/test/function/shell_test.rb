# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"
require "timeout"
require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Function
    module Shell
      class ShellTest < Minitest::Test
        def test_executable_accepts_absolute_path
          with_executable("absolute-tool") do |path|
            assert(Function.executable?(path))
          end
        end

        def test_executable_accepts_relative_path
          Dir.mktmpdir do |dir|
            path = ::File.join(dir, "relative-tool")
            ::File.write(path, "#!/bin/sh\n")
            FileUtils.chmod("+x", path)

            Dir.chdir(dir) do
              assert(Function.executable?("./relative-tool"))
            end
          end
        end

        def test_executable_rejects_directories
          Dir.mktmpdir do |dir|
            executable_dir = ::File.join(dir, "tool-dir")
            ::Dir.mkdir(executable_dir)
            FileUtils.chmod("+x", executable_dir)

            with_path(dir) do
              refute(Function.executable?("tool-dir"))
            end
          end
        end

        def test_executable_accepts_symlinked_files
          Dir.mktmpdir do |dir|
            target = ::File.join(dir, "target-tool")
            link = ::File.join(dir, "linked-tool")
            ::File.write(target, "#!/bin/sh\n")
            FileUtils.chmod("+x", target)
            ::File.symlink(target, link)

            with_path(dir) do
              assert(Function.executable?("linked-tool"))
            end
          end
        end

        def test_executable_accepts_empty_path_segment
          Dir.mktmpdir do |dir|
            path = ::File.join(dir, "local-tool")
            ::File.write(path, "#!/bin/sh\n")
            FileUtils.chmod("+x", path)

            Dir.chdir(dir) do
              with_exact_path(["", ENV.fetch("PATH", nil)].compact.join(::File::PATH_SEPARATOR)) do
                assert(Function.executable?("local-tool"))
              end
            end
          end
        end

        def test_executable_observes_path_mutation
          Dir.mktmpdir do |dir|
            path = ::File.join(dir, "mutable-tool")

            with_exact_path("") do
              refute(Function.executable?("mutable-tool"))

              ::File.write(path, "#!/bin/sh\n")
              FileUtils.chmod("+x", path)
              ENV["PATH"] = dir

              assert(Function.executable?("mutable-tool"))
            end
          end
        end

        def test_executable_returns_false_without_path
          path = ENV.fetch("PATH", nil)
          ENV.delete("PATH")

          refute(Function.executable?("missing-tool"))
        ensure
          ENV["PATH"] = path
        end

        def test_executable_rejects_blank_program
          refute(Function.executable?(nil))
          refute(Function.executable?(""))
        end

        def test_executable_bang_raises_for_missing_program
          error = assert_raises(Error) { Function.executable!("missing-tool --version") }

          assert_equal("Missing executable: missing-tool --version", error.message)
        end

        def test_executable_bang_accepts_absolute_path_with_spaces
          with_executable("tool with spaces") do |path|
            Function.executable!(path)
          end
        end

        def test_executable_bang_rejects_blank_program
          error = assert_raises(Error) { Function.executable!("") }

          assert_equal("Missing executable: ", error.message)
        end

        def test_sh_bang_checks_executable_from_first_argument
          checked = nil
          ran = nil
          result = Result.new(args: ["tool", "--version"], outs: [], errs: [], exit_code: 0, signal: nil)

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

          command = Shellwords.join([ruby, "-e", "$stderr.puts \"bad\"; exit 7"])
          assert_equal("Command failed: #{command}", error.message)
        end

        def test_sh_rejects_empty_command
          assert_raises(ArgumentError) { Function.sh }
          assert_raises(ArgumentError) { Function.sh! }
        end

        def test_result_reports_exit_and_signal_status
          success = Function.sh(RbConfig.ruby, "-e", "exit 0")
          failure = Function.sh(RbConfig.ruby, "-e", "exit 7")
          signaled = Function.sh(RbConfig.ruby, "-e", "Process.kill(\"TERM\", Process.pid)")

          assert(success.ok?)
          refute(success.notok?)
          refute(success.signaled?)
          assert_equal(0, success.exit_code)

          refute(failure.ok?)
          assert(failure.notok?)
          refute(failure.signaled?)
          assert_equal(7, failure.exit_code)

          refute(signaled.ok?)
          assert(signaled.notok?)
          assert(signaled.signaled?)
          assert_nil(signaled.exit_code)
          assert_equal(Signal.list.fetch("TERM"), signaled.signal)
        end

        def test_result_owns_inputs_and_escapes_display
          command = +"two words"
          output = +"out"
          error = +"err"
          result = Result.new(args: [command, "'quoted'", 42], outs: [output], errs: [error], exit_code: 0, signal: nil)

          command.clear
          output.clear
          error.clear

          assert_equal(["two words", "'quoted'", "42"], result.args)
          assert_equal(["out"], result.outs)
          assert_equal(["err"], result.errs)
          assert_equal("two\\ words \\'quoted\\' 42", result.cmd)
          [result, result.args, result.outs, result.errs, *result.args, *result.outs, *result.errs].each do |value|
            assert_predicate(value, :frozen?)
          end
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

        def test_sh_real_sigint_escalates_without_trap_errors
          Dir.mktmpdir do |dir|
            completed = false
            ready = ::File.join(dir, "ready")
            term = ::File.join(dir, "term")
            child = <<~RUBY
              Signal.trap("TERM") { File.write(#{term.inspect}, "TERM") }
              File.write(#{ready.inspect}, Process.pid)
              loop { sleep(1) }
            RUBY
            script = <<~RUBY
              require "rbconfig"
              require "sevgi/function"
              baseline = Thread.list.count
              restored = false
              Signal.trap("INT") { restored = true }
              result = Sevgi::Function.sh(RbConfig.ruby, "-e", #{child.inspect})
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
            stop_probe(::File.read(ready).to_i) if !completed && ready && ::File.exist?(ready)
          end
        end

        def test_sh_real_sigint_reaches_overlapping_children
          Dir.mktmpdir do |dir|
            completed = false
            ready = 2.times.map { ::File.join(dir, "ready#{it}") }
            term = 2.times.map { ::File.join(dir, "term#{it}") }
            children = 2.times.map do |index|
              <<~RUBY
                Signal.trap("TERM") { File.write(#{term[index].inspect}, "TERM"); exit(23) }
                File.write(#{ready[index].inspect}, Process.pid)
                loop { sleep(1) }
              RUBY
            end

            script = <<~RUBY
              require "rbconfig"
              require "sevgi/function"
              restored = false
              Signal.trap("INT") { restored = true }
              children = #{children.inspect}
              results = children.map do |child|
                Thread.new { Sevgi::Function.sh(RbConfig.ruby, "-e", child) }
              end.map(&:value)
              Process.kill("INT", Process.pid)
              puts(*results.map { it.exit_code.inspect }, restored.inspect)
            RUBY

            out, err, status = run_signal_probe(script, ready) { Process.kill("INT", it) }
            completed = status.success?

            assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
            assert_equal(%w[23 23 true], out.lines(chomp: true))
            assert(term.all? { ::File.exist?(it) })
            refute_includes(err, "trap context")
          ensure
            Array(ready).each { stop_probe(::File.read(it).to_i) if !completed && ::File.exist?(it) }
          end
        end

        def test_sh_signal_dispatch_survives_runner_error
          bad = Object.new
          def bad.handle_sigint(*) = raise "broken runner"

          good = Runner.new
          signals = []

          Process.stub(:kill, -> (signal, pid) { signals << [signal, pid] }) do
            Signals.register(bad, 1)
            Signals.register(good, 2)
            _out, err = capture_io { Signals.send(:dispatch) }

            assert_includes(err, "SIGINT dispatch failed: broken runner")
          ensure
            Signals.unregister(bad)
            Signals.unregister(good)
          end

          assert_equal([["TERM", 2]], signals)
        end

        def test_sh_coordinates_overlapping_signal_handlers
          baseline = proc { }
          previous = Signal.trap("INT", baseline)
          first = Runner.new
          second = Runner.new
          signals = []

          Process.stub(:kill, -> (signal, pid) { signals << [signal, pid] }) do
            Signals.register(first, 1)
            Signals.register(second, 2)
            Signals.send(:dispatch)
            Signals.send(:dispatch)
            Signals.unregister(first)

            current = Signal.trap("INT", "DEFAULT")
            refute_same(baseline, current)
            Signal.trap("INT", current)

            2.times { Signals.unregister(second) }
            restored = Signal.trap("INT", "DEFAULT")
            assert_same(baseline, restored)
          end

          assert_equal(
            [["TERM", 1], ["TERM", 2], ["KILL", 1], ["KILL", 2]],
            signals
          )
        ensure
          Signals.unregister(first) if first
          Signals.unregister(second) if second
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

        def run_signal_probe(script, ready)
          lib = ::File.expand_path("../../lib", __dir__)
          rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(::File::PATH_SEPARATOR)

          ::Open3.popen3({"RUBYLIB" => rubylib}, RbConfig.ruby, "-e", script) do |stdin, stdout, stderr, thread|
            stdin.close
            Array(ready).each { wait_for_file(it) }
            yield(thread.pid)
            status = Timeout.timeout(3) { thread.value }

            return [stdout.read, stderr.read, status]
          ensure
            stop_probe(thread.pid) if thread&.alive?
          end
        end

        def stop_probe(pid)
          ::Process.kill("KILL", pid)
        rescue Errno::ESRCH
          nil
        end

        def wait_for_file(path)
          Timeout.timeout(2) do
            sleep(0.01) until ::File.exist?(path)
          end
        end

        def with_executable(program)
          Dir.mktmpdir do |dir|
            path = ::File.join(dir, program)
            ::File.write(path, "#!/bin/sh\n")
            FileUtils.chmod("+x", path)

            with_path(dir) do
              yield path
            end
          end
        end

        def with_exact_path(value)
          path = ENV.fetch("PATH", nil)
          ENV["PATH"] = value
          yield
        ensure
          ENV["PATH"] = path
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
