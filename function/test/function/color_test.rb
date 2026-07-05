# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Function
    module Color
      class ColorTest < Minitest::Test
        def test_color_helpers_wrap_ansi_sequences
          assert_equal("\e[1m\e[38;5;35mok\e[0m", Function.green("ok"))
          assert_equal("\e[1m\e[2mok\e[0m", Function.dim("ok"))
        end
      end
    end
  end
end
