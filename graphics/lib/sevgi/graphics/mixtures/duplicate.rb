# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for duplicating elements and their subtrees.
      module Duplicate
        # Duplicates an element subtree and optionally translates it.
        # @param dx [Numeric, nil] x translation
        # @param dy [Numeric, nil] y translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @return [Sevgi::Graphics::Element] duplicated element
        def Duplicate(dx: nil, dy: nil, parent: nil, &block)
          duplicated = dup

          duplicated.Traverse() do |element|
            element.children = element.children.map(&:dup)
            id = (element.attributes = element.attributes.dup).delete(:id)
            element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"] = id if id
            block&.call(element)
          end

          duplicated.Translate(dx, dy) if dx || dy

          duplicated.Adopt(parent)

          duplicated
        end

        # Duplicates an element subtree along the x-axis.
        # @param dx [Numeric] x translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @return [Sevgi::Graphics::Element] duplicated element
        def DuplicateX(dx, parent: nil, &block) = Duplicate(dx:, dy: 0, parent:, &block)

        # Duplicates an element subtree along the y-axis.
        # @param dy [Numeric] y translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @return [Sevgi::Graphics::Element] duplicated element
        def DuplicateY(dy, parent: nil, &block) = Duplicate(dx: 0, dy:, parent:, &block)
      end
    end
  end
end
