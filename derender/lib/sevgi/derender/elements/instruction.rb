# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      # Preserves XML processing instructions as inert markup.
      # @api private
      module Instruction
        # Converts a processing instruction into a floating DSL node.
        # @return [Array<String>] unformatted Ruby source lines
        def decompile(*)
          ["_ Sevgi::Graphics::Content.verbatim(#{Ruby.literal(content)})"]
        end
      end
    end
  end
end
