# frozen_string_literal: true

require "fileutils"
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
            assert Function.executable?("cached-tool")

            FileUtils.rm(path)

            assert Function.executable?("cached-tool")
          end
        end

        def test_executable_caches_negative_result
          Dir.mktmpdir do |dir|
            with_path(dir) do
              clear_executable_cache

              refute Function.executable?("missing-tool")

              path = ::File.join(dir, "missing-tool")
              ::File.write(path, "#!/bin/sh\n")
              FileUtils.chmod("+x", path)

              refute Function.executable?("missing-tool")
            end
          end
        end

        def test_executable_bang_raises_for_missing_program
          clear_executable_cache

          error = assert_raises(RuntimeError) { Function.executable!("missing-tool --version") }

          assert_equal "Missing executable: missing-tool", error.message
        end

        def test_sh_bang_checks_executable_from_first_argument
          checked = nil
          ran     = nil
          result  = Result.new([ "tool", "--version" ], [], [], 0)

          Function.stub(:executable!, ->(*args) { checked = args }) do
            Function.stub(:sh, ->(*args) { ran = args; result }) do
              assert_same result, Function.sh!("tool", "--version")
            end
          end

          assert_equal [ "tool", "--version" ], checked
          assert_equal [ "tool", "--version" ], ran
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
            path = ENV["PATH"]
            ENV["PATH"] = [ dir, path ].join(::File::PATH_SEPARATOR)
            yield
          ensure
            ENV["PATH"] = path
          end
      end
    end
  end
end
