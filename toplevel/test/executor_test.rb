# frozen_string_literal: true

require_relative "./test_helper"

module Sevgi
  class ExecutorTest < Minitest::Test
    FIXTURES_DIR = ::File.expand_path("#{__dir__}/fixtures/executor")

    def test_load_panics
      fixture = "#{FIXTURES_DIR}/test_load_shutdown.sevgi"

      assert_raises(PanicError) { Executor.load(fixture) }
    end

    def test_execute_file
      skip
      fixture = "#{FIXTURES_DIR}/test_load_nested.sevgi"

      result = Sevgi.execute_file(fixture)

      assert(result.error?)
      assert_instance_of(Executor::Error, result.error)
      assert_equal([
        "#{FIXTURES_DIR}/test_load_nested.sevgi",
        "#{FIXTURES_DIR}/test_load_nested_1.sevgi",
        "#{FIXTURES_DIR}/test_load_nested_2.sevgi",
      ], result.stack)
      [
        "#{FIXTURES_DIR}/test_load_nested_2.sevgi:3",
        "#{FIXTURES_DIR}/test_load_nested_1.sevgi:3",
        "#{FIXTURES_DIR}/test_load_nested.sevgi:5",
      ].map { it.delete_prefix("#{Dir.pwd}/") }
        .zip (
          result.error.backtrace!.map { it.split(":")[0..1].join(":") }
      ).each do |expected, actual|
        assert_equal(expected, actual)
      end
    end

    def test_execute_boot_default
      pp foobar if respond_to?(:foobar)
      refute_respond_to(self, :foobar)
      result = Executor.execute("foobar") do
        extend(Module.new { def foobar = "default" })
      end
      assert_equal("default", result.recent)
      refute_respond_to(self, :foobar)
    end

    def test_execute_boot_toplevel
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

    def test_execute_empty_string
      assert_nil(Executor.execute(""))
    end

    def test_execute_returns_last_expression
      assert_equal(15, Executor.execute("x = 5\ny = 10\nx + y").recent)
    end

    def test_execute_error_reports_correct_file_and_line_without_arguments
      syntax_error = "de foo\n  invalid syntax here\nend"

      result = Executor.execute(syntax_error)

      assert(result.error?)
      assert(result.error.message.start_with?("sevgi:3:"))
    end

    def test_execute_error_reports_correct_file_and_line_with_arguments
      syntax_error = "de foo\n  invalid syntax here\nend"

      result = Executor.execute(syntax_error, file: "test.rb", line: 10)

      assert(result.error?)
      assert(result.error.message.start_with?("test.rb:12:"))
    end
  end
end
