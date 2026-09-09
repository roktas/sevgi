# frozen_string_literal: true

require "tmpdir"

require_relative "test_helper"

module Sevgi
  class ExecutorLoadDepthTest < Minitest::Test
    def test_execute_file_limits_active_sources_and_recovers
      Dir.mktmpdir do |dir|
        files = Array.new(129) { |i| File.join(dir, "load_#{i}.sevgi") }
        files.each_cons(2) do |current, following|
          File.write(current, "Load #{File.basename(following, ".sevgi").dump}\n42\n")
        end

        File.write(files.last, "42\n")

        boundary = Sevgi.execute_file(files[1])
        assert_nil(boundary.error)
        assert_equal(42, boundary.value)

        result = Sevgi.execute_file(files.first)

        assert_instance_of(Executor::LoadDepthError, result.error.cause)
        assert_match(/load nesting too deep/i, result.error.message)
        assert_match(/maximum 128 active sources/, result.error.message)

        recovered = Sevgi.execute_file(files[1])
        assert_nil(recovered.error)
        assert_equal(42, recovered.value)
      end
    end
  end
end
