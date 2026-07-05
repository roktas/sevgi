# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Function
    module UI
      class UITest < Minitest::Test
        def test_mayok_reports_when_not_silent
          silent = ENV.fetch("SILENT", nil)
          ENV.delete("SILENT")

          out, err = capture_io { Function.mayok("ready") }

          assert_empty(out)
          assert_includes(err, "ready")
        ensure
          ENV["SILENT"] = silent
        end

        def test_mayok_skips_when_silent
          silent = ENV.fetch("SILENT", nil)
          ENV["SILENT"] = "1"

          out, err = capture_io { Function.mayok("ready") }

          assert_empty(out)
          assert_empty(err)
        ensure
          ENV["SILENT"] = silent
        end

        def test_ui_reports_status_and_returns_value
          result = nil

          out, err = capture_io do
            result = Function.ui("build") { :done }
          end

          assert_equal(:done, result)
          assert_empty(out)
          assert_includes(err, "build")
        end
      end
    end
  end
end
