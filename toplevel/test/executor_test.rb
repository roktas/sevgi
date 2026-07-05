# frozen_string_literal: true

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

    def test_execute_installs_dsl_in_isolated_scope
      result = Sevgi.execute(
        <<~RUBY
          Paper(3, 5, :executor_test_card)
          [
            SVG(:minimal, :executor_test_card).Render(validate: false),
            F.pluralize("cat"),
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
        Geometry::Origin,
        result.recent[2],
        Sundries::Export,
        result.recent[3]
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
    end

    def test_execute_require_error_preserves_active_scope
      result = Executor.execute(
        <<~RUBY
          before = Sevgi::Executor.instance.current
          begin
            Sevgi::Executor.execute("1", require: "sevgi_missing_test_library")
          rescue LoadError
            before.equal?(Sevgi::Executor.instance.current)
          end
        RUBY
      )

      assert_equal(true, result.recent)
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
  end
end
