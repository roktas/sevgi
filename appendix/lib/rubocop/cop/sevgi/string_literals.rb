# frozen_string_literal: true

require "rubocop/cop/style/string_literals"

module RuboCop
  module Cop
    module Sevgi
      # Uses double-quoted strings consistently in Sevgi DSL source.
      class StringLiterals < Style::StringLiterals
      end
    end
  end
end
