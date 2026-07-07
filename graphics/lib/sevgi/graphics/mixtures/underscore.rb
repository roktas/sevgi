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
        # @param comment [String] comment text
        # @return [Sevgi::Graphics::Element] floating comment element
        def Comment(comment)
          _(Content.verbatim("<!-- #{comment} -->"))
        end

        # Merges internal ancestral attributes from the document root to this element.
        # @return [Hash] merged internal attributes
        def Ancestral
          {}.tap do |result|
            Root().Traverse() { |element| result.merge!(element[:_]) if element.has?(:_) }
          end
        end
      end
    end
  end
end
