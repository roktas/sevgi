# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # Compatibility helpers for profiles that do not load richer mixtures.
      module Polyfills
        # @overload layer(*args, **attributes)
        #   Builds a generic group as a layer fallback.
        #   @param args [Array<Object>] group content arguments
        #   @param attributes [Hash] group attributes
        #   @return [Sevgi::Graphics::Element] group element
        def layer(...) = g(...)

        # @overload symbol!(*args, **attributes)
        #   Builds a regular symbol as a fallback for hidden symbols.
        #   @param args [Array<Object>] symbol content arguments
        #   @param attributes [Hash] symbol attributes
        #   @return [Sevgi::Graphics::Element] symbol element
        def symbol!(...) = symbol(...)
      end
    end
  end
end
