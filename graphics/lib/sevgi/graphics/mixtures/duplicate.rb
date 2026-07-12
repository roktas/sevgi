# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for duplicating independent element subtrees.
      module Duplicate
        # Duplicates an element subtree as an independent tree and optionally translates it.
        # Copied elements receive new child arrays, attribute stores, and content arrays. Visible `id` attributes are
        # moved to non-rendering `-id` metadata before the optional block runs, allowing the block to derive replacement
        # ids without rendering duplicates. A pre-existing `-id` takes precedence over the visible id.
        # @param dx [Numeric, nil] x translation
        # @param dy [Numeric, nil] y translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        # @raise [Sevgi::ArgumentError] when copied attributes or contents contain cyclic payloads
        # @example Remap source ids on a duplicate
        #   source = SVG { rect(id: "shape") }.children.first
        #   copy = source.Duplicate do |node|
        #     node[:id] = "#{node[:"-id"]}-copy" if node[:"-id"]
        #   end
        def Duplicate(dx: nil, dy: nil, parent: nil, &block)
          duplicated = Subtree.copy(self)
          Subtree.prepare(duplicated, &block)
          Subtree.translate(duplicated, dx, dy)
          Subtree.attach(duplicated, self, parent)
        end

        # Duplicates an element subtree along the x-axis.
        # @param dx [Numeric] x translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        # @raise [Sevgi::ArgumentError] when copied attributes or contents contain cyclic payloads
        def DuplicateX(dx, parent: nil, &block) = Duplicate(dx:, dy: 0, parent:, &block)

        # Duplicates an element subtree along the y-axis.
        # @param dy [Numeric] y translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        # @raise [Sevgi::ArgumentError] when copied attributes or contents contain cyclic payloads
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
              duplicated.send(:contents=, element.contents.map(&:dup))
              duplicated.send(:children=, element.children.map { |child| copy(child, duplicated) })
            end
          end

          # Removes copied public ids and applies an optional customization hook.
          # @api private
          def self.prepare(element, &block)
            element.Traverse() do |node|
              if node.attributes.has?(:id)
                id = node.attributes.delete(:id)
                metadata = :"#{ATTRIBUTE_INTERNAL_PREFIX}id"
                node[metadata] = id unless node.attributes.has?(metadata)
              end

              block&.call(node)
            end
          end

          # Applies an optional translation to a copied subtree.
          # @api private
          def self.translate(element, dx, dy)
            element.Translate(dx || 0, dy) if dx || dy
          end

          # Attaches a copied subtree unless it is a detached root copy.
          # @api private
          def self.attach(element, source, parent)
            element.Adopt(parent) if parent || !source.Root?()
            element
          end
        end

        private_constant :Subtree
      end
    end
  end
end
