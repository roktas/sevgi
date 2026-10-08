# frozen_string_literal: true

require_relative "style/declaration"

module Sevgi
  module Graphics
    module Mixtures
      # Document-local declarations for editable PDF export.
      module Style
        # Reads or replaces this document's Style declaration.
        # A declaration changes export metadata, not rendered SVG appearance.
        # Ordinary document copies safely share the immutable declaration.
        # @param definition [Hash, Sevgi::Undefined] declaration, or omitted for a read
        # @yield defines Target, Param, Group, and Profiles records
        # @yieldreturn [Object] ignored block result
        # @return [Hash, nil, Sevgi::Graphics::Element] frozen JSON declaration on read, self on assignment
        # @raise [Sevgi::ArgumentError] when called outside a document root or with an invalid declaration
        # @example Declare an editable outline
        #   drawing.Style do
        #     Target "ink", selectors: ["#outline"]
        #     Param "display", targets: ["ink"], property: "display",
        #       schema: {type: "string", enum: %w[inline none]}
        #     Param "opacity", targets: ["ink"], property: "stroke-opacity",
        #       schema: {type: "number", minimum: 0, maximum: 1}
        #   end
        def Style(definition = Undefined, &block)
          ArgumentError.("Style belongs to a document root") unless Root?()
          return @style&.to_h if definition.equal?(Undefined) && !block
          definition = {} if definition.equal?(Undefined)
          @style = Declaration.new(definition, &block)
          self
        end
      end
    end
  end
end
