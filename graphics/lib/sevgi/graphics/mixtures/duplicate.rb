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
        # Translation and parent channels are validated before the subtree is copied or the customization block runs.
        # @param dx [Numeric, nil] finite x translation; nil omits the axis
        # @param dy [Numeric, nil] finite y translation; nil omits the axis
        # @param parent [Sevgi::Graphics::Element, nil] explicit parent, or the source parent when nil
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        # @raise [Sevgi::ArgumentError] when a translation is not a finite real number
        # @raise [Sevgi::ArgumentError] when copied attributes or contents contain cyclic payloads
        # @example Remap source ids on a duplicate
        #   source = SVG { rect(id: "shape") }.children.first
        #   copy = source.Duplicate do |node|
        #     node[:id] = "#{node[:"-id"]}-copy" if node[:"-id"]
        #   end
        def Duplicate(dx: nil, dy: nil, parent: nil, &block)
          dx, dy, target = Subtree.channels(self, dx, dy, parent)
          duplicated = Subtree.copy(self)
          Subtree.prepare(duplicated, &block)
          Subtree.translate(duplicated, dx, dy)
          Subtree.attach(duplicated, target)
        end

        # Duplicates an element subtree along the x-axis.
        # @param dx [Numeric] x translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        # @raise [Sevgi::ArgumentError] when dx is not a finite real number
        # @raise [Sevgi::ArgumentError] when copied attributes or contents contain cyclic payloads
        def DuplicateX(dx, parent: nil, &block)
          ArgumentError.("Duplicate x translation cannot be nil") if dx.nil?
          Duplicate(dx:, dy: 0, parent:, &block)
        end

        # Duplicates an element subtree along the y-axis.
        # @param dy [Numeric] y translation
        # @param parent [Sevgi::Graphics::Element, nil] parent for the duplicated subtree
        # @yield [element] optional customization hook for each copied element
        # @yieldparam element [Sevgi::Graphics::Element] copied element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] duplicated element
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        # @raise [Sevgi::ArgumentError] when dy is not a finite real number
        # @raise [Sevgi::ArgumentError] when copied attributes or contents contain cyclic payloads
        def DuplicateY(dy, parent: nil, &block)
          ArgumentError.("Duplicate y translation cannot be nil") if dy.nil?
          Duplicate(dx: 0, dy:, parent:, &block)
        end

        # Recursive subtree copier that keeps duplicate implementation state out of the DSL surface.
        # @api private
        module Subtree
          # Validates and normalizes duplicate option channels before copying.
          # @return [Array<(Integer, Float, Sevgi::Graphics::Element, nil)>] normalized dx, dy, and target parent
          # @raise [Sevgi::ArgumentError] when a translation or parent is invalid
          def self.channels(source, dx, dy, parent)
            target = parent.nil? ? source.parent : parent
            unless target.nil? || source.instance_of?(target.class)
              ArgumentError.("Element type does not match the new parent type: #{source.class}")
            end

            dx = Scalar.number(dx, context: "duplicate translation", field: :x) unless dx.nil?
            dy = Scalar.number(dy, context: "duplicate translation", field: :y) unless dy.nil?
            [dx, dy, target]
          end

          # Builds an independent copy of an element subtree.
          # @param element [Sevgi::Graphics::Element] source subtree root
          # @param parent [Sevgi::Graphics::Element, Object] parent for the copied root
          # @return [Sevgi::Graphics::Element] copied subtree root
          def self.copy(element, parent = Element.send(:tree_parent, element))
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
                metadata = :"#{Attributes::META_PREFIX}id"
                node[metadata] = id unless node.attributes.has?(metadata)
              end

              block&.call(node)
            end
          end

          # Applies an optional translation to a copied subtree.
          # @api private
          def self.translate(element, dx, dy)
            element.Translate(dx || 0, dy) unless dx.nil? && dy.nil?
          end

          # Attaches a copied subtree unless it is a detached root copy.
          # @api private
          def self.attach(element, target)
            element.Adopt(target) if target
            element
          end
        end

        private_constant :Subtree
      end
    end
  end
end
