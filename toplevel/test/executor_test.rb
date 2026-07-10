# frozen_string_literal: true

require "tmpdir"

require_relative "test_helper"

module Sevgi
  class ExecutorTest < Minitest::Test
    FIXTURES_DIR = ::File.expand_path("#{__dir__}/fixtures/executor")

    def test_load_raises_panic_error
      fixture = "#{FIXTURES_DIR}/test_load_shutdown.sevgi"

      assert_raises(PanicError) { Executor.load(fixture) }
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
            .backtrace!
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
        result.error.backtrace!.map { it.split(":")[0..1].join(":") }
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
      assert_equal("recursive load", result.error.message)
      assert_equal(
        [
          "#{FIXTURES_DIR}/test_load_recursive_outer.sevgi:3",
          "#{FIXTURES_DIR}/test_load_recursive_inner.sevgi:3",
          "#{FIXTURES_DIR}/test_load_recursive_outer.sevgi:6"
        ].map { it.delete_prefix("#{Dir.pwd}/") },
        result.error.backtrace!.map { it.split(":")[0..1].join(":") }
      )
    end

    def test_execute_file_reloads_duplicate_load_source
      fixture = "#{FIXTURES_DIR}/test_load_repeated.sevgi"

      result = Sevgi.execute_file(fixture)

      assert_equal(2, result.recent)
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
      assert_instance_of(::Errno::ENOENT, result.error.error)
      assert_equal([missing], result.stack)
    end

    def test_execute_wraps_required_load_error
      result = Executor.execute("1", file: "script.sevgi", require: "sevgi_missing_test_library")

      assert(result.error?)
      assert_instance_of(Executor::Error, result.error)
      assert_instance_of(::LoadError, result.error.error)
      assert_match(/sevgi_missing_test_library/, result.error.message)
      assert_equal(["script.sevgi"], result.stack)
    end

    def test_execute_preserves_nested_load_error
      Dir.mktmpdir do |dir|
        library = ::File.join(dir, "outer.rb")
        ::File.write(library, "require 'sevgi_missing_nested_dependency'\n")

        result = Executor.execute("1", file: "script.sevgi", require: library.delete_suffix(".rb"))

        assert(result.error?)
        assert_instance_of(::LoadError, result.error.error)
        assert_match(/sevgi_missing_nested_dependency/, result.error.message)
        refute_match(/outer/, result.error.message)
        assert_equal(["script.sevgi"], result.stack)
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
      result = Executor.execute(
        <<~RUBY
          before = Sevgi::Executor.instance.current
          Sevgi::Executor.execute("")
          before.equal?(Sevgi::Executor.instance.current)
        RUBY
      )

      assert_equal(true, result.recent)
    end

    def test_execute_empty_string_preserves_signal_guard
      executor = Executor.instance
      executor.send(:trap)

      begin
        assert_equal(1, executor.instance_variable_get(:@signal_count))
        Executor.execute("")
        assert_equal(1, executor.instance_variable_get(:@signal_count))
      ensure
        executor.send(:restore)
      end
    end

    def test_execute_empty_string_processes_required_library
      result = Executor.execute("", require: "json")

      assert_equal("Sevgi::Executor::Scope", result.class.name)
      assert_nil(result.recent)
      refute(result.error?)
    end

    def test_execute_installs_dsl_in_isolated_scope
      result = Sevgi.execute(
        <<~RUBY
          Paper(3, 5, :executor_test_card)
          [
            SVG(:minimal, :executor_test_card).Render(validate: false),
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
        result.recent[0],
        "cats",
        result.recent[1],
        true,
        result.recent[2],
        true,
        result.recent[3],
        Geometry::Origin,
        result.recent[4],
        Sundries::Export,
        result.recent[5]
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
    end

    def test_execute_require_error_preserves_active_scope
      result = Executor.execute(
        <<~RUBY
          before = Sevgi::Executor.instance.current
          inner = Sevgi::Executor.execute("1", require: "sevgi_missing_test_library")
          before.equal?(Sevgi::Executor.instance.current) && inner.error?
        RUBY
      )

      assert_equal(true, result.recent)
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
      assert_instance_of(ArgumentError, result.error.error)
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

      assert_equal("default", result.recent)
      refute_respond_to(self, :foobar)
    end

    def test_execute_boots_toplevel_receiver
      refute_respond_to(self, :foobar)
      result = Executor.execute("module A; foobar; end", receiver: TOPLEVEL_BINDING.receiver) do
        include(Module.new { def foobar = "toplevel" })
      end

      assert_equal("toplevel", result.recent)
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

    def test_execute_returns_nil_for_empty_string
      assert_nil(Executor.execute(""))
    end

    def test_execute_returns_last_expression
      assert_equal(15, Executor.execute("x = 5\ny = 10\nx + y").recent)
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

    def assert_concurrent_load_result(result, label, paths)
      actual, scope, error = result

      assert_equal(label, actual)
      assert_nil(error)
      assert_equal(label, scope.recent)
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
