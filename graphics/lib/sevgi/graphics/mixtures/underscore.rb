# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for floating text, comments, and inherited internal attributes.
      module Underscore
        # Creates a floating content element.
        # @param contents [Array<Object>] text or content objects
        # @return [Sevgi::Graphics::Element] floating element
        def _(*contents)
          Element(:_, *contents)
        end

        # Adds an XML comment.
        # @param comment [Object] comment text
        # @return [Sevgi::Graphics::Element] floating comment element
        # @raise [Sevgi::ArgumentError] when comment cannot be stringified as valid XML or would form malformed markup
        def Comment(comment)
          comment = XML.text(comment, context: "XML comment")

          ArgumentError.("XML comment must not contain '--'") if comment.include?("--")
          ArgumentError.("XML comment must not end with '-'") if comment.end_with?("-")

          _(Content.verbatim("<!-- #{comment} -->"))
        end

        # Merges internal attributes from the document root, ancestors, and this element.
        # Only the direct root-to-self ancestor chain participates; sibling subtrees are ignored. When the same key is
        # present on multiple chain elements, the nearest element to the receiver wins.
        # @return [Hash] merged internal attributes
        def Ancestral
          chain = []
          TraverseUp { |element| chain.unshift(element) }

          {}.tap do |result|
            chain.each { |element| result.merge!(element[:_]) if element.has?(:_) }
          end
        end
      end
    end
  end
end
