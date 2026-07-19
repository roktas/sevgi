# frozen_string_literal: true

require "rubocop/cop/style/block_delimiters"

module RuboCop
  module Cop
    # Cops that preserve the visual rhythm of executable Sevgi DSL source.
    module Sevgi
      # Uses braces for one-line blocks and do/end for multiline blocks.
      class BlockDelimiters < Style::BlockDelimiters
      end
    end
  end
end
