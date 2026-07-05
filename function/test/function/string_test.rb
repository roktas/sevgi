# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Function
    module String
      class StringTest < Minitest::Test
        def test_demodulize_returns_leaf_name
          [
            "String",
            Function.demodulize(::String),
            "String",
            Function.demodulize("Sevgi::Function::String"),
            "Plain",
            Function.demodulize("Plain")
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_pluralize_handles_common_words
          [
            "",
            Function.pluralize(""),
            "children",
            Function.pluralize("child"),
            "octopi",
            Function.pluralize("octopus"),
            "sheep",
            Function.pluralize("sheep"),
            "words",
            Function.pluralize("words"),
            "CamelOctopi",
            Function.pluralize("CamelOctopus")
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end
      end
    end
  end
end
