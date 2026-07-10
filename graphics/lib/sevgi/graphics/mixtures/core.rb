# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Graphics
    module Mixtures
      # Traversal stop token returned by {Core#Stay}.
      #
      # @!attribute [r] value
      #   @return [Object] value returned from traversal
      Stop = Data.define(:value)

      # Internal traversal engine.
      # @api private
      module Traversal
        # Runs a depth-first traversal.
        # @param element [Sevgi::Graphics::Element] starting element
        # @param depth [Integer] starting depth
        # @param leave [Proc, nil] optional leave callback
        # @return [Sevgi::Graphics::Element, Object]
        def self.call(element, depth, leave, &block)
          catch(:traversal) do
            visit(element, depth, leave, &block)
            element
          end
        end

        def self.stop(value)
          throw(:traversal, value.value) if value.is_a?(Stop)
        end

        def self.visit(element, depth, leave, &block)
          stop(block.call(element, depth))
          element.children.each { |child| visit(child, depth + 1, leave, &block) }
          stop(leave.call(element, depth)) if leave
        end

        private_class_method :stop, :visit
      end

      private_constant :Traversal

      # Core SVG tree and attribute DSL helpers.
      module Core
        extend Forwardable
        def_delegators :@attributes, :[], :[]=, :has?
        def_delegators :@children, :first, :last, :at

        # Moves this element under a new parent.
        # @param new_parent [Sevgi::Graphics::Element, nil] target parent or current parent
        # @param index [Integer] insertion index
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when the target parent has a different element class
        # @raise [Sevgi::ArgumentError] when the target parent is this element or one of its descendants
        def Adopt(new_parent = nil, index: -1)
          tap do
            if new_parent
              unless instance_of?(new_parent.class)
                ArgumentError.("Element type does not match the new parent type: #{self.class}")
              end
            else
              new_parent = parent
            end

            Adoption.validate(self, new_parent)

            self.Orphan()
            (@parent = new_parent).children.insert(index, self)
          end
        end

        # @overload AdoptFirst(new_parent = nil)
        #   Moves this element to the beginning of a parent.
        #   @param new_parent [Sevgi::Graphics::Element, nil] target parent or current parent
        #   @return [Sevgi::Graphics::Element] self
        #   @raise [Sevgi::ArgumentError] when the target parent has a different element class
        #   @raise [Sevgi::ArgumentError] when the target parent is this element or one of its descendants
        def AdoptFirst(*)
          Adopt(*, index: 0)
        end

        # Appends existing elements as children.
        # @param elements [Array<Sevgi::Graphics::Element>] elements to append
        # @return [Sevgi::Graphics::Element] self
        def Append(*elements)
          tap { elements.each { it.Adopt(self) } }
        end

        # Adds CSS classes without duplicating existing values.
        # @param classes [Array<String, Symbol, Array>] class tokens; strings are split on whitespace
        # @return [Sevgi::Graphics::Element] self
        def Classify(*classes)
          tap do
            tokens = proc do |value|
              case value
              when nil
                []
              when ::Array
                value.flat_map { tokens.call(it) }
              else
                value.to_s.split
              end
            end

            self[:class] = [*tokens.call(self[:class]), *tokens.call(classes)].uniq
          end
        end

        # Assigns default attributes only when they are absent.
        # @param attributes [Hash] default attributes
        # @return [Sevgi::Graphics::Element] self
        def Defaults(**attributes)
          tap do
            attributes.each do |key, value|
              next if has?(key)

              self[key] = value
            end
          end
        end

        # Builds a child element with an explicit tag name.
        # @param tag [Symbol, String] SVG tag name
        # @param contents [Array<Object>] text or content objects; non-content objects are stringified and XML-encoded
        # @param attributes [Hash] SVG attributes
        # @return [Sevgi::Graphics::Element] new child element
        def Element(tag, *contents, **attributes, &block)
          self.class.send(:new, tag.to_sym, contents: Content.contents(*contents), attributes:, parent: self, &block)
        end

        # Forwards this element as the first argument to another receiver.
        # @overload Forward(receiver, method, *args, **kwargs)
        #   @param receiver [Object] target receiver
        #   @param method [Symbol, String] method name
        #   @param args [Array<Object>] additional arguments
        #   @param kwargs [Hash] additional keyword arguments
        #   @return [Object] forwarded call result
        def Forward(receiver, method, ...)
          receiver.public_send(method, self, ...)
        end

        # Reports whether this element has the given SVG name.
        # @param name [Symbol, String] SVG name
        # @return [Boolean]
        def Is?(name)
          self.name() == name.to_sym
        end

        # Removes this element from its parent.
        # @return [Array<Sevgi::Graphics::Element>, nil] parent children after deletion, or nil for root elements
        def Orphan
          parent.children&.delete(self) unless Root?()
        end

        # Prepends existing elements as children.
        # @param elements [Array<Sevgi::Graphics::Element>] elements to prepend
        # @return [Sevgi::Graphics::Element] self
        def Prepend(*elements)
          tap { elements.each { it.AdoptFirst(self) } }
        end

        # Returns the root document element.
        # @return [Sevgi::Graphics::Element]
        def Root
          element = self
          element = element.parent until element.Root?()

          element
        end

        # Reports whether this element is the root document element.
        # @return [Boolean]
        def Root?
          self.class.root?(self)
        end

        # @overload Stay(value)
        #   Wraps a traversal return value as a stop token.
        #   @param value [Object] value returned from traversal
        #   @return [Sevgi::Graphics::Mixtures::Stop]
        def Stay(...) = Stop.new(...)

        # Traverses the subtree depth-first.
        # @param depth [Integer] starting depth
        # @param leave [Proc, nil] optional leave callback
        # @return [Sevgi::Graphics::Element, Object] self or the value passed through Stay
        # @raise [Sevgi::ArgumentError] when no block is given
        def Traverse(depth = 0, leave = nil, &block)
          ArgumentError.("Block required") unless block

          Traversal.call(self, depth, leave, &block)
        end

        # Traverses ancestors from this element to the root.
        # @param height [Integer] starting height
        # @return [Object, nil] value passed through Stay, or nil
        # @raise [Sevgi::ArgumentError] when no block is given
        def TraverseUp(height = 0, &block)
          ArgumentError.("Block required") unless block

          element = self

          loop do
            yield(element, height).tap { return it.value if it.is_a?(Stop) }

            break if element.Root?()

            element = element.parent
            height += 1
          end
        end

        # Evaluates a block in the parent element context.
        # @param args [Array<Object>] optional receiver override followed by block arguments
        # @param kwargs [Hash] keyword arguments passed to the block
        # @return [Sevgi::Graphics::Element] self
        def With(*args, **kwargs, &block)
          tap { (args.shift || self).parent.instance_exec(*args, **kwargs, &block) }
        end

        # Evaluates a block in this element context.
        # @param args [Array<Object>] optional receiver override followed by block arguments
        # @param kwargs [Hash] keyword arguments passed to the block
        # @return [Sevgi::Graphics::Element] self
        def Within(*args, **kwargs, &block)
          tap { (args.shift || self).instance_exec(*args, **kwargs, &block) }
        end

        # Appends an element as a child.
        # @param element [Sevgi::Graphics::Element] element to append
        # @return [Sevgi::Graphics::Element] self
        def <<(element)
          Append(element)
        end

        # Adoption target validation that keeps tree mutation atomic.
        # @api private
        module Adoption
          # Rejects target parents that would create a cycle.
          # @param element [Sevgi::Graphics::Element] element being moved
          # @param parent [Sevgi::Graphics::Element, Object] target parent
          # @return [void]
          # @raise [Sevgi::ArgumentError] when the target parent is this element or one of its descendants
          def self.validate(element, parent)
            ArgumentError.("Element cannot be adopted under itself") if parent.equal?(element)

            while parent.respond_to?(:Root?)
              ArgumentError.("Element cannot be adopted under its descendant") if parent.equal?(element)
              break if parent.Root?()

              parent = parent.parent
            end
          end
        end

        private_constant :Adoption
      end
    end
  end
end
