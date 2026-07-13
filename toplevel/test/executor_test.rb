# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"

require_relative "test_helper"

module Sevgi
  class ExecutorTest < Minitest::Test
    FIXTURES_DIR = ::File.expand_path("#{__dir__}/fixtures/executor")

    def test_executor_entrypoint_loads_standalone
      root = ::File.expand_path("../..", __dir__)
      load_paths = %w[function toplevel].map { ::File.join(root, it, "lib") }
      command = "require \"sevgi/executor\"; abort unless Sevgi::Executor.execute(\"1 + 1\").value == 2"
      args = [::RbConfig.ruby, "--disable-gems", *load_paths.flat_map { ["-I", it] }, "-e", command]

      output, error, status = ::Open3.capture3(*args)

      assert(status.success?, "stdout:\n#{output}\nstderr:\n#{error}")
    end

    def test_load_raises_panic_error
      fixture = "#{FIXTURES_DIR}/test_load_shutdown.sevgi"

      assert_raises(PanicError) { Executor.__send__(:load, fixture) }
    end

    def test_executor_exposes_only_execution_entrypoints
      assert_respond_to(Executor, :execute)
      assert_respond_to(Executor, :execute_file)
      %i[instance load shutdown].each { refute_respond_to(Executor, it) }
      assert_raises(NameError) { Executor::State }
    end

    def test_execute_file_reports_nested_load_stack
      fixture = "#{FIXTURES_DIR}/test_load_nested.sevgi"

      result = Sevgi.execute_file(fixture)

      assert(result.error?)
      assert_instance_of(Executor::Error, result.error)
      assert_kind_of(::Sevgi::Error, result.error)
      assert_equal(
        [
          "#{FIXTURES_DIR}/test_load_nested.sevgi",
          "#{FIXTURES_DIR}/test_load_nested_1.sevgi",
          "#{FIXTURES_DIR}/test_load_nested_2.sevgi"
        ],
        result.stack
      )
      [
        "#{FIXTURES_DIR}/test_load_nested_2.sevgi:3",
        "#{FIXTURES_DIR}/test_load_nested_1.sevgi:3",
        "#{FIXTURES_DIR}/test_load_nested.sevgi:3"
      ]
        .map { it.delete_prefix("#{Dir.pwd}/") }
        .zip(
          result
            .error
            .load_backtrace
            .map { it.split(":")[0..1].join(":") }
            .each
        ) do |expected, actual|
          assert_equal(expected, actual)
        end
    end

    def test_execute_file_keeps_successful_load_source
      fixture = "#{FIXTURES_DIR}/test_load_after.sevgi"

      result = Sevgi.execute_file(fixture)

      assert(result.error?)
      assert_equal(
        [
          fixture,
          "#{FIXTURES_DIR}/test_load_value.sevgi"
        ],
        result.stack
      )
      assert_equal(
        ["#{FIXTURES_DIR}/test_load_after.sevgi:4"].map { it.delete_prefix("#{Dir.pwd}/") },
        result.error.load_backtrace.map { it.split(":")[0..1].join(":") }
      )
    end

    def test_execute_file_deduplicates_recursive_load_stack
      fixture = "#{FIXTURES_DIR}/test_load_recursive_outer.sevgi"

      result = Sevgi.execute_file(fixture)

      assert(result.error?)
      assert_equal(
        [
          fixture,
          "#{FIXTURES_DIR}/test_load_recursive_inner.sevgi"
        ],
        result.stack
      )
      assert_instance_of(Executor::CycleError, result.error.cause)
      assert_match(/Recursive Sevgi load/, result.error.message)
      assert_equal(
        [
          "#{FIXTURES_DIR}/test_load_recursive_inner.sevgi:3",
          "#{FIXTURES_DIR}/test_load_recursive_outer.sevgi:6"
        ].map { it.delete_prefix("#{Dir.pwd}/") },
        result.error.load_backtrace.map { it.split(":")[0..1].join(":") }
      )
    end

    def test_execute_file_reloads_duplicate_load_source
      fixture = "#{FIXTURES_DIR}/test_load_repeated.sevgi"

      result = Sevgi.execute_file(fixture)

      assert_equal(2, result.value)
      assert_equal(
        [
          fixture,
          "#{FIXTURES_DIR}/test_load_counter.sevgi"
        ],
        result.stack
      )
    end

    def test_execute_file_wraps_missing_file
      missing = "#{FIXTURES_DIR}/missing.sevgi"

      result = Sevgi.execute_file(missing)

      assert(result.error?)
      assert_instance_of(Executor::Error, result.error)
      assert_instance_of(::Errno::ENOENT, result.error.cause)
      assert_equal([missing], result.stack)
    end

    def test_execute_wraps_required_load_error
      result = Executor.execute("1", file: "script.sevgi", require: "sevgi_missing_test_library")

      assert(result.error?)
      assert_instance_of(Executor::Error, result.error)
      assert_instance_of(::LoadError, result.error.cause)
      assert_match(/sevgi_missing_test_library/, result.error.message)
      assert_equal(["script.sevgi"], result.stack)
    end

    def test_execute_preserves_nested_load_error
      Dir.mktmpdir do |dir|
        library = ::File.join(dir, "outer.rb")
        ::File.write(library, "require 'sevgi_missing_nested_dependency'\n")

        result = Executor.execute("1", file: "script.sevgi", require: library.delete_suffix(".rb"))

        assert(result.error?)
        assert_instance_of(::LoadError, result.error.cause)
        assert_match(/sevgi_missing_nested_dependency/, result.error.message)
        refute_match(/outer/, result.error.message)
        assert_equal(["script.sevgi"], result.stack)
      end
    end

    def test_execute_file_rejects_direct_load_cycle
      Dir.mktmpdir do |dir|
        file = File.join(dir, "self.sevgi")
        File.write(file, "Load 'self'\n")

        result = Sevgi.execute_file(file)

        assert_instance_of(Executor::CycleError, result.error.cause)
        assert_match(/Recursive Sevgi load/, result.error.message)
        assert_equal([file], result.stack)
      end
    end

    def test_execute_file_rejects_two_file_cycle
      Dir.mktmpdir do |dir|
        first = File.join(dir, "first.sevgi")
        second = File.join(dir, "second.sevgi")
        File.write(first, "Load 'second'\n")
        File.write(second, "Load 'first'\n")

        result = Sevgi.execute_file(first)

        assert_instance_of(Executor::CycleError, result.error.cause)
        assert_equal([first, second], result.stack)
        assert_includes(result.error.message, first)
      end
    end

    def test_execute_file_rejects_symlink_cycle_by_canonical_identity
      Dir.mktmpdir do |dir|
        real = File.join(dir, "real.sevgi")
        alias_file = File.join(dir, "alias.sevgi")
        File.write(real, "Load 'alias'\n")
        File.symlink(real, alias_file)

        result = Sevgi.execute_file(real)

        assert_instance_of(Executor::CycleError, result.error.cause)
        assert_equal([real, alias_file], result.stack)
      end
    end

    def test_execute_file_isolates_concurrent_load_scopes
      Dir.mktmpdir do |dir|
        paths = write_concurrent_load_scripts(dir)
        ready = Queue.new
        results = Queue.new
        go = {a: Queue.new, b: Queue.new}

        a = run_concurrent_load(:a, paths[:a][:outer], ready, go[:a], results)
        assert_equal(:a, ready.pop)

        b = run_concurrent_load(:b, paths[:b][:outer], ready, go[:b], results)
        assert_equal(:b, ready.pop)

        go[:a].push(true)
        assert_concurrent_load_result(results.pop, :a, paths[:a])

        go[:b].push(true)
        assert_concurrent_load_result(results.pop, :b, paths[:b])

        [a, b].each(&:join)
      end
    end

    def test_execute_empty_string_preserves_active_scope
      fixture = "#{FIXTURES_DIR}/test_load_shutdown.sevgi"
      result = Sevgi.execute(
        <<~RUBY
          inner = Sevgi::Executor.execute("")
          Load(#{fixture.dump})
          [inner.success?, inner.stack]
        RUBY
      )

      assert_equal([true, []], result.value)
    end

    def test_empty_source_and_file_entrypoints_are_strict_noops
      Dir.mktmpdir do |dir|
        file = ::File.join(dir, "empty.sevgi")
        ::File.write(file, "")
        receivers = Array.new(4) { Module.new }
        boots = 0
        results = [
          Executor.execute("", receiver: receivers[0]) { boots += 1 },
          Sevgi.execute("", receiver: receivers[1]),
          Executor.execute_file(file, receiver: receivers[2]) { boots += 1 },
          Sevgi.execute_file(file, receiver: receivers[3])
        ]

        results.each do |result|
          assert_predicate(result, :success?)
          assert_nil(result.value)
          assert_empty(result.stack)
        end

        assert_equal(0, boots)
        receivers.each { refute_respond_to(it, :Paper) }
      end
    end

    def test_execute_empty_string_preserves_signal_guard
      previous = Signal.trap("INT", "DEFAULT")
      handler = proc { }
      Signal.trap("INT", handler)

      begin
        Executor.execute("")
        assert_same(handler, Signal.trap("INT", "DEFAULT"))
      ensure
        Signal.trap("INT", previous)
      end
    end

    def test_execute_empty_string_processes_required_library
      receiver = Object.new
      seen = nil
      result = Executor.execute("", file: "required.sevgi", require: "json", receiver:) { seen = self }

      assert_instance_of(Executor::Result, result)
      assert_nil(result.value)
      refute(result.error?)
      assert_same(receiver, seen)
      assert_equal(["required.sevgi"], result.stack)
    end

    def test_toplevel_empty_source_with_required_library_runs_boot
      receiver = Module.new
      result = Sevgi.execute("", require: "json", receiver:)

      assert_predicate(result, :success?)
      assert_respond_to(receiver, :Paper)
      assert_equal(["sevgi"], result.stack)
    end

    def test_execute_installs_dsl_in_isolated_scope
      result = Sevgi.execute(
        <<~RUBY
          Paper(3, 5, :executor_test_card)
          [
            SVG(:minimal, :executor_test_card).Render(),
            F.pluralize("cat"),
            F.equal?(Sevgi::F),
            F.respond_to?(:existing!),
            Origin,
            Export
          ]
        RUBY
      )

      [
        false,
        respond_to?(:Paper, true),
        false,
        Object.const_defined?(:F, false),
        "<svg width=\"3.0mm\" height=\"5.0mm\" viewBox=\"0 0 3 5\"/>",
        result.value[0],
        "cats",
        result.value[1],
        true,
        result.value[2],
        true,
        result.value[3],
        Geometry::Origin,
        result.value[4],
        Sundries::Export,
        result.value[5]
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
    end

    def test_execute_require_error_preserves_active_scope
      fixture = "#{FIXTURES_DIR}/test_load_shutdown.sevgi"
      result = Sevgi.execute(
        <<~RUBY
          inner = Sevgi::Executor.execute("1", require: "sevgi_missing_test_library")
          Load(#{fixture.dump})
          inner.error?
        RUBY
      )

      assert_equal(true, result.value)
    end

    def test_execute_isolates_main_constant
      old = Sevgi.const_get(:Main, false) if Sevgi.const_defined?(:Main, false)
      Sevgi.send(:remove_const, :Main) if Sevgi.const_defined?(:Main, false)

      result = Executor.execute("missing")

      refute(Sevgi.const_defined?(:Main, false))
      assert_equal("undefined local variable or method 'missing' for module Sevgi::Main", result.error.message)
    ensure
      Sevgi.send(:remove_const, :Main) if Sevgi.const_defined?(:Main, false)
      Sevgi.const_set(:Main, old) if old
    end

    def test_execute_paper_rejects_conflicting_profile
      result = Sevgi.execute(
        <<~RUBY
          Paper(3, 5, :executor_test_conflict)
          Paper(7, 11, :executor_test_conflict)
        RUBY
      )

      assert(result.error?)
      assert_instance_of(ArgumentError, result.error.cause)
      assert_match(/\bexecutor_test_conflict\b/, result.error.message)
    end

    def test_execute_restores_sigint_handler
      original = Signal.trap("INT", "DEFAULT")
      handler = proc { }

      Signal.trap("INT", handler)

      Executor.execute("1")

      assert_same(handler, Signal.trap("INT", "IGNORE"))
    ensure
      Signal.trap("INT", original)
    end

    def test_execute_restores_sigint_handler_after_concurrent_execute
      original = Signal.trap("INT", "DEFAULT")
      handler = proc { }

      Signal.trap("INT", handler)

      ready = Queue.new
      results = Queue.new
      go = {a: Queue.new, b: Queue.new}

      a = run_concurrent_execute(:a, ready, go[:a], results)
      assert_equal(:a, ready.pop)

      b = run_concurrent_execute(:b, ready, go[:b], results)
      assert_equal(:b, ready.pop)

      go[:a].push(true)
      assert_equal(:a, results.pop)

      go[:b].push(true)
      assert_equal(:b, results.pop)

      [a, b].each(&:join)

      assert_same(handler, Signal.trap("INT", "IGNORE"))
    ensure
      Signal.trap("INT", original)
    end

    def test_execute_boots_isolated_receiver
      pp(foobar) if respond_to?(:foobar)
      refute_respond_to(self, :foobar)
      result = Executor.execute("foobar") do
        extend(Module.new { def foobar = "default" })
      end

      assert_equal("default", result.value)
      refute_respond_to(self, :foobar)
    end

    def test_execute_preserves_explicit_boot_receivers
      object = Object.new
      mod = Module.new

      [nil, false, object, mod].each do |receiver|
        seen = nil
        result = Executor.execute("1", receiver:) { seen = self }

        assert_equal(1, result.value)
        if receiver.nil?
          assert_instance_of(Module, seen)
          assert_equal("Sevgi::Main", seen.name)
        else
          assert_same(receiver, seen)
        end
      end
    end

    def test_execute_isolates_nested_boot_receivers
      outer = Object.new
      inner = false
      seen = []

      result = Executor.execute("42", receiver: outer) do
        seen << self
        nested = Executor.execute("6 * 7", receiver: inner) { seen << self }
        seen << nested.value
      end

      assert_equal(42, result.value)
      assert_same(outer, seen[0])
      assert_same(inner, seen[1])
      assert_equal(42, seen[2])
    end

    def test_execute_isolates_concurrent_boot_receivers
      receivers = [Object.new, false, Module.new]
      ready = Queue.new
      release = Queue.new

      results = receivers.map { concurrent_boot(it, ready, release) }

      receivers.size.times { ready.pop }
      receivers.size.times { release << true }

      results.each do |thread|
        receiver, seen, value = thread.value
        assert_same(receiver, seen)
        assert_equal(1, value)
      end

    ensure
      receivers&.size&.times { release << true } if release
      results&.each(&:join)
    end

    def test_execute_boots_toplevel_receiver
      refute_respond_to(self, :foobar)
      result = Executor.execute("module A; foobar; end", receiver: TOPLEVEL_BINDING.receiver) do
        include(Module.new { def foobar = "toplevel" })
      end

      assert_equal("toplevel", result.value)
      assert_respond_to(self, :foobar)
    ensure
      method(:foobar).owner.send(:undef_method, :foobar)
      refute_respond_to(self, :foobar)
    end

    def test_execute_isolates_constants
      Executor.execute("ISOLATED_CONST = 42")

      refute(defined?(::ISOLATED_CONST), "Constant should not leak to global namespace")
    end

    def test_execute_isolates_classes
      Executor.execute("class IsolatedClass; end")

      refute(defined?(::IsolatedClass), "Class should not leak to global namespace")
    end

    def test_execute_isolates_methods
      Executor.execute("def isolated_method = 'test'", file: "methods.rb", line: 1)

      refute(respond_to?(:isolated_method), "Method should not leak to global scope")
    end

    def test_execute_returns_success_for_empty_string
      result = Executor.execute("")

      assert_instance_of(Executor::Result, result)
      assert_predicate(result, :frozen?)
      assert_predicate(result, :success?)
      refute_predicate(result, :error?)
      assert_nil(result.value)
      assert_nil(result.error)
      assert_empty(result.stack)
      assert_predicate(result.stack, :frozen?)
    end

    def test_result_owns_source_stack
      source = +"drawing.sevgi"
      stack = [source]
      result = Executor::Result.new(value: nil, error: nil, stack:)

      source.clear
      stack.clear

      assert_equal(["drawing.sevgi"], result.stack)
      assert_predicate(result.stack.first, :frozen?)
    end

    def test_executor_error_handles_absent_backtraces
      [nil, []].each do |backtrace|
        cause = RuntimeError.new("boom")
        cause.set_backtrace(backtrace) if backtrace
        error = Executor::Error.new(cause, ["script.sevgi"])

        assert_same(cause, error.cause)
        assert_equal([], error.load_backtrace)
      end
    end

    def test_executor_error_owns_source_stack
      relative = +"relative.sevgi"
      absolute = +File.expand_path("absolute.sevgi")
      stack = [relative, absolute]
      cause = RuntimeError.new("boom")
      cause.set_backtrace(
        [
          "relative.sevgi:3:in 'draw'",
          "#{absolute}:4:in 'render'",
          "other.rb:5:in 'ignore'"
        ]
      )
      error = Executor::Error.new(cause, stack)

      relative.replace("changed.sevgi")
      absolute.replace("changed-too.sevgi")
      stack.clear

      assert_equal(
        ["relative.sevgi:3:in 'draw'", "absolute.sevgi:4:in 'render'"],
        error.load_backtrace
      )

      owned = error.instance_variable_get(:@stack)
      assert_predicate(owned, :frozen?)
      assert(owned.all?(&:frozen?))
    end

    def test_execute_returns_failure_status
      result = Executor.execute("missing", file: "script.sevgi")

      refute_predicate(result, :success?)
      assert_predicate(result, :error?)
      assert_instance_of(NameError, result.error.cause)
      assert_equal(["script.sevgi"], result.stack)
    end

    def test_execute_returns_last_expression
      assert_equal(15, Executor.execute("x = 5\ny = 10\nx + y").value)
    end

    def test_execute_rejects_invalid_invocation
      calls = [
        proc { Executor.execute(nil) },
        proc { Executor.execute("1", file: 1) },
        proc { Executor.execute("1", line: "1") },
        proc { Executor.execute("1", line: 0) },
        proc { Executor.execute("1", line: 2 ** 31) },
        proc { Executor.execute("1", require: :json) },
        proc { Executor.execute("1", receiver: BasicObject.new) }
      ]

      calls.each { assert_raises(Sevgi::ArgumentError, &it) }
      assert_equal(2, Executor.execute("1 + 1").value)
    end

    def test_execute_file_rejects_invalid_invocation
      calls = [
        proc { Executor.execute_file(nil) },
        proc { Executor.execute_file("missing.sevgi", require: :json) },
        proc { Executor.execute_file("missing.sevgi", receiver: BasicObject.new) }
      ]

      calls.each { assert_raises(Sevgi::ArgumentError, &it) }
      assert_equal(2, Executor.execute("1 + 1").value)
    end

    def test_execute_error_reports_default_source_location
      syntax_error = "de foo\n  invalid syntax here\nend"

      result = Executor.execute(syntax_error)

      assert(result.error?)
      assert(result.error.message.start_with?("sevgi:3:"))
    end

    def test_execute_error_reports_custom_source_location
      syntax_error = "de foo\n  invalid syntax here\nend"

      result = Executor.execute(syntax_error, file: "test.rb", line: 10)

      assert(result.error?)
      assert(result.error.message.start_with?("test.rb:12:"))
    end

    private

    def concurrent_boot(receiver, ready, release)
      Thread.new do
        seen = nil
        result = Executor.execute("1", receiver:) do
          seen = self
          ready << true
          release.pop
        end

        [receiver, seen, result.value]
      end
    end

    def assert_concurrent_load_result(result, label, paths)
      actual, scope, error = result

      assert_equal(label, actual)
      assert_nil(error)
      assert_equal(label, scope.value)
      assert_equal([paths[:outer], paths[:inner]], scope.stack)
    end

    def run_concurrent_execute(label, ready, go, results)
      Thread.new do
        Thread.current[:executor_test_ready] = ready
        Thread.current[:executor_test_go] = go

        Executor.execute(
          <<~RUBY
            Thread.current[:executor_test_ready].push(#{label.inspect})
            Thread.current[:executor_test_go].pop
          RUBY
        )

        results.push(label)
      end
    end

    def run_concurrent_load(label, file, ready, go, results)
      Thread.new do
        Thread.current[:executor_test_ready] = ready
        Thread.current[:executor_test_go] = go

        results.push([label, Sevgi.execute_file(file), nil])
      rescue StandardError => e
        results.push([label, nil, e])
      end
    end

    def write_concurrent_load_scripts(dir)
      %i[a b].to_h do |label|
        inner = ::File.join(dir, "inner_#{label}.sevgi")
        outer = ::File.join(dir, "outer_#{label}.sevgi")

        ::File.write(
          inner,
          <<~RUBY
            @loaded = #{label.inspect}
          RUBY
        )
        ::File.write(
          outer,
          <<~RUBY
            Thread.current[:executor_test_ready].push(#{label.inspect})
            Thread.current[:executor_test_go].pop
            Load "inner_#{label}"
            @loaded
          RUBY
        )

        [label, {inner:, outer:}]
      end
    end
  end
end
