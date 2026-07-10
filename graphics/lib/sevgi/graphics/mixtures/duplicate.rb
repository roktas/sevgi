# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for duplicating independent element subtrees.
      module Duplicate
        # Duplicates an element subtree as an independent tree and optionally translates it.
        # Copied elements receive new child arrays, attribute stores, and content arrays. Public `id` attributes are
        # moved to an internal `-id` attribute before the optional block runs, allowing the block to derive replacement
        # ids without rendering duplicate public ids.
        # @param dx [Numeric, nil] x translation
        # @param dy [Numeric, nil] y translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        def Duplicate(dx: nil, dy: nil, parent: nil, &block)
          duplicated = Subtree.copy(self)

          duplicated.Traverse() do |element|
            id = element.attributes.delete(:id)
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
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        def DuplicateX(dx, parent: nil, &block) = Duplicate(dx:, dy: 0, parent:, &block)

        # Duplicates an element subtree along the y-axis.
        # @param dy [Numeric] y translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        def DuplicateY(dy, parent: nil, &block) = Duplicate(dx: 0, dy:, parent:, &block)

        # Recursive subtree copier that keeps duplicate implementation state out of the DSL surface.
        # @api private
        module Subtree
          # Builds an independent copy of an element subtree.
          # @param element [Sevgi::Graphics::Element] source subtree root
          # @param parent [Sevgi::Graphics::Element, Object] parent for the copied root
          # @return [Sevgi::Graphics::Element] copied subtree root
          def self.copy(element, parent = element.parent)
            element.dup.tap do |duplicated|
              duplicated.send(:parent=, parent)
              duplicated.send(:attributes=, element.attributes.dup)
              duplicated.send(:contents=, element.contents.dup)
              duplicated.send(:children=, element.children.map { |child| copy(child, duplicated) })
            end
          end
        end

        private_constant :Subtree
      end
    end
  end
end
