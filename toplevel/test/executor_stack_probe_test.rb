# frozen_string_literal: true

require "tmpdir"

require_relative "test_helper"

module Sevgi
  class ExecutorStackProbeTest < Minitest::Test
    def test_probe_unguarded_load_stack_depth
      scope = Executor.const_get(:Scope, false)
      scope.send(:remove_const, :MAX_LOAD_DEPTH)
      scope.const_set(:MAX_LOAD_DEPTH, 10_000)

      Dir.mktmpdir do |dir|
        files = Array.new(3_000) { |i| File.join(dir, "probe_#{i}.sevgi") }
        files.each_cons(2) do |current, following|
          File.write(current, "Load #{File.basename(following, ".sevgi").dump}\n")
        end
        File.write(files.last, "42\n")

        result = Sevgi.execute_file(files.first)
        warn "SEVGI LOAD STACK PROBE: cause=#{result.error&.cause&.class} visited=#{result.stack.size}"
      end
    ensure
      scope.send(:remove_const, :MAX_LOAD_DEPTH) if scope.const_defined?(:MAX_LOAD_DEPTH, false)
      scope.const_set(:MAX_LOAD_DEPTH, 128)
      scope.send(:private_constant, :MAX_LOAD_DEPTH)
    end
  end
end
