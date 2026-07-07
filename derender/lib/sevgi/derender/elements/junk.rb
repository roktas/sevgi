# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      # Element strategy for comments and ignored XML nodes.
      # @api private
      module Junk
        # Drops ignored nodes from generated source.
        # @return [Array<String>] empty source lines
        def decompile(*) = []
      end
    end
  end
end
