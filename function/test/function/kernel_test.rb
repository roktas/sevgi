# frozen_string_literal: true

require_relative "../test_helper"

require "tempfile"

module Sevgi
  module Function
    module Kernel
      class KernelTest < Minitest::Test
        def setup
          @no_error     = "x = 10; x * 2"
          @syntax_error = "de foo\n  invalid syntax here\nend"
          @name_error   = "undefined_variable + 1"
        end

        def test_eval_returns_evaluation_result
          assert_equal(4, Function.eval("2 + 2"))
        end

        def test_eval_with_file_and_line
          assert_equal(15, Function.eval("5 * 3", "custom.rb", 42))
        end

        def test_eval_with_nil_file_and_line
          assert_equal(100, Function.eval("100", nil, nil))
        end

        def test_eval_custom_inspect
          assert_nil(Function.eval("class Foo; end", "test.rb", 1, inspect: "MyCustomInspect"))
        end

        def test_eval_default_inspect_message
          error = assert_raises(SyntaxError) do
            Function.eval(@syntax_error, "test.rb", 1)
          end

          assert(error.message.start_with?("test.rb:3:"))
        end

        def test_eval_syntax_error_reports_correct_file_and_line
          error = assert_raises(SyntaxError) do
            Function.eval(@syntax_error, "test.rb", 10)
          end

          assert(error.message.start_with?("test.rb:12:"))
        end

        def test_eval_name_error_reports_correct_file_and_line
          error = assert_raises(NameError) do
            Function.eval(@name_error, "vars.rb", 5)
          end

          assert(error.backtrace.first.start_with?("vars.rb:5:"))
        end

        def test_eval_runtime_error_reports_correct_location
          error = assert_raises(ZeroDivisionError) do
            Function.eval("1 / 0", "math.rb", 7)
          end

          assert(error.backtrace.first.start_with?("math.rb:7:"))
        end

        def test_eval_isolates_constants
          Function.eval("ISOLATED_CONST = 42", "isolation.rb", 1)

          refute(defined?(::ISOLATED_CONST), "Constant should not leak to global namespace")
        end

        def test_eval_isolates_classes
          Function.eval("class IsolatedClass; end", "isolation.rb", 1)

          refute(defined?(::IsolatedClass), "Class should not leak to global namespace")
        end

        def test_eval_isolates_methods
          Function.eval("def isolated_method = 'test'", "methods.rb", 1)

          refute(respond_to?(:isolated_method), "Method should not leak to global scope")
        end

        def test_eval_multiline_code
          multiline = <<~RUBY
            a = 1
            b = 2
            a + b
          RUBY

          assert_equal(3, Function.eval(multiline, "multi.rb", 1))
        end

        def test_eval_empty_string
          assert_nil(Function.eval("", "empty.rb", 1))
        end

        def test_eval_returns_last_expression
          assert_equal(15, Function.eval("x = 5\ny = 10\nx + y", "expr.rb", 1))
        end

        def test_load_returns_true
          Tempfile.create([ "test", ".rb" ]) do |file|
            file.write("x = 5")
            file.flush

            assert_equal(true, Function.load(file.path))
          end
        end

        def test_load_reads_and_evaluates_file
          Tempfile.create([ "calc", ".rb" ]) do |file|
            file.write("2 + 3")
            file.flush

            assert_equal(true, Function.load(file.path))
          end
        end

        def test_load_with_custom_inspect
          Tempfile.create([ "custom", ".rb" ]) do |file|
            file.write("class Bar; end")
            file.flush

            assert_equal(true, Function.load(file.path, inspect: "CustomLoader"))
          end
        end

        def test_load_syntax_error_reports_correct_file_and_line
          Tempfile.create([ "syntax_error", ".rb" ]) do |file|
            file.write(@syntax_error)
            file.flush

            error = assert_raises(SyntaxError) do
              Function.load(file.path)
            end

            assert(error.message.start_with?("#{file.path}:3:"))
          end
        end

        def test_load_name_error_reports_correct_file
          Tempfile.create([ "name_error", ".rb" ]) do |file|
            file.write(@name_error)
            file.flush

            error = assert_raises(NameError) do
              Function.load(file.path)
            end

            assert(error.message.include?("#{file.path}"))
          end
        end

        def test_load_file_not_found
          error = assert_raises(Errno::ENOENT) do
            Function.load("/nonexistent/file.rb")
          end

          assert(error.message.include?("No such file or directory"))
        end

        def test_load_isolates_constants
          Tempfile.create([ "const", ".rb" ]) do |file|
            file.write("LOADED_CONST = 99")
            file.flush

            Function.load(file.path)

            refute(defined?(::LOADED_CONST), "Constant should not leak to global namespace")
          end
        end

        def test_load_isolates_classes
          Tempfile.create([ "class", ".rb" ]) do |file|
            file.write("class LoadedClass; end")
            file.flush

            Function.load(file.path)

            refute(defined?(::LoadedClass), "Class should not leak to global namespace")
          end
        end

        def test_load_multiline_file
          Tempfile.create([ "multiline", ".rb" ]) do |file|
            file.write(<<~RUBY)
              x = 10
              y = 20
              x + y
            RUBY
            file.flush

            assert_equal(true, Function.load(file.path))
          end
        end

        def test_load_empty_file
          Tempfile.create([ "empty", ".rb" ]) do |file|
            file.write("")
            file.flush

            assert_equal(true, Function.load(file.path))
          end
        end

        def test_load_default_inspect_uses_filename
          Tempfile.create([ "inspect_test", ".rb" ]) do |file|
            file.write(@name_error)
            file.flush

            error = assert_raises(NameError) do
              Function.load(file.path)
            end

            assert(error.message.include?("(loaded from #{file.path})"))
          end
        end

        def test_load_uses_eval_internally
          Tempfile.create([ "integration", ".rb" ]) do |file|
            file.write("INTEGRATION_TEST = 123")
            file.flush

            Function.load(file.path)

            refute(defined?(::INTEGRATION_TEST))
          end
        end

        def test_load_starts_at_line_1
          Tempfile.create([ "line_start", ".rb" ]) do |file|
            file.write(@name_error)
            file.flush

            error = assert_raises(NameError) do
              Function.load(file.path)
            end

            assert(error.backtrace.first.start_with?("#{file.path}:1:"))
          end
        end
      end
    end
  end
end
