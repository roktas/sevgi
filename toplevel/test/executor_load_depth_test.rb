# frozen_string_literal: true

require "tmpdir"

require_relative "test_helper"

module Sevgi
  class ExecutorLoadDepthTest < Minitest::Test
    def test_execute_file_reports_excessive_load_nesting_before_ruby_stack_overflow
      scope = Executor.const_get(:Scope, false)
      maximum = scope.const_get(:MAX_LOAD_DEPTH, false)

      Dir.mktmpdir do |dir|
        files = Array.new(maximum + 1) { |i| File.join(dir, "load_#{i}.sevgi") }
        files.each_cons(2) do |current, following|
          File.write(current, "Load #{File.basename(following, '.sevgi').dump}\n")
        end
        File.write(files.last, "42\n")

        result = Sevgi.execute_file(files.first)

        assert_instance_of(Executor::LoadDepthError, result.error.cause)
        refute_instance_of(SystemStackError, result.error.cause)
        assert_match(/load nesting too deep/i, result.error.message)
        assert_match(/indirect recursion/i, result.error.message)
      end
    end
  end
end
