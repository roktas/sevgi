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

      # Element strategy for CDATA sections.
      # @api private
      module CData
        # Converts CDATA into a floating content node.
        # @return [Array<String>] unformatted Ruby source lines
        def decompile(*)
          markup = "<![CDATA[#{Graphics.const_get(:XML).cdata(content)}]]>"
          ["_ Sevgi::Graphics::Content.verbatim(#{Ruby.literal(markup)})"]
        end
      end
    end
  end
end
