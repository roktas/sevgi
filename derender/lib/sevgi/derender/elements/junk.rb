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

      # Element strategy for XML comments.
      # @api private
      module Comment
        # Converts a comment into a floating DSL node.
        # @return [Array<String>] unformatted Ruby source lines
        def decompile(*)
          markup = "<!--#{content}-->"
          ["_ Sevgi::Graphics::Content.verbatim(#{Ruby.literal(markup)})"]
        end
      end
    end
  end
end
