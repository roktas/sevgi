# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      # Element strategy for text nodes.
      # @api private
      module Text
        # Converts a text node into unformatted Sevgi DSL lines.
        # @return [Array<String>] unformatted Ruby source lines
        def decompile(*) = ["_ #{Ruby.literal(content)}"]
      end
    end
  end
end
