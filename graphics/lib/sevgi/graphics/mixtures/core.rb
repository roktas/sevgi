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
        # @raise [Sevgi::ArgumentError] when index is not an Integer insertion position
        def Adopt(new_parent = nil, index: -1)
          tap do
            new_parent ||= parent
            Adoption.validate(self, new_parent)

            insertion = Adoption.index_for(self, new_parent, index)

            self.Orphan()
            Element.send(:attach, self, new_parent, index: insertion)
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

        # Appends distinct existing elements as children in argument order.
        # Each element transfers from its current parent. The complete batch is validated before any element moves.
        # @param elements [Array<Sevgi::Graphics::Element>] distinct elements to append
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when an argument has a different element class, is repeated, or is this target or its ancestor
        def Append(*elements)
          tap { Adoption.batch(elements, self, front: false) }
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
        # @yield evaluates the drawing DSL in the new child element
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] new child element
        # @raise [Sevgi::ArgumentError] when the tag, attributes, or content are not valid XML
        def Element(tag, *contents, **attributes, &block)
          self.class.send(:new, tag, contents: Content.contents(*contents), attributes:, parent: self, &block)
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

        # Removes this element from its parent and makes it a detached subtree root.
        # @return [Sevgi::Graphics::Element, nil] self, or nil for root elements
        def Orphan
          return if Root?()

          Element.send(:detach, self)
          self
        end

        # Prepends distinct existing elements as children in argument order.
        # Each element transfers from its current parent. The complete batch is validated before any element moves.
        # @param elements [Array<Sevgi::Graphics::Element>] distinct elements to prepend
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when an argument has a different element class, is repeated, or is this target or its ancestor
        def Prepend(*elements)
          tap { Adoption.batch(elements, self, front: true) }
        end

        # Returns the root document element.
        # @return [Sevgi::Graphics::Element]
        def Root
          element = self
          element = element.parent while element.parent

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
        # @yield [element, depth] visits each element before its children
        # @yieldparam element [Sevgi::Graphics::Element] visited element
        # @yieldparam depth [Integer] element depth
        # @yieldreturn [Object] ignored unless it is a {Stop} token
        # @return [Sevgi::Graphics::Element, Object] self or the value passed through Stay
        # @raise [Sevgi::ArgumentError] when no block is given
        def Traverse(depth = 0, leave = nil, &block)
          ArgumentError.("Block required") unless block

          Traversal.call(self, depth, leave, &block)
        end

        # Traverses ancestors from this element to the root.
        # @param height [Integer] starting height
        # @yield [element, height] visits this element and each ancestor
        # @yieldparam element [Sevgi::Graphics::Element] visited element
        # @yieldparam height [Integer] ancestor height
        # @yieldreturn [Object] ignored unless it is a {Stop} token
        # @return [Object, nil] value passed through Stay, or nil
        # @raise [Sevgi::ArgumentError] when no block is given
        def TraverseUp(height = 0, &block)
          ArgumentError.("Block required") unless block

          element = self

          loop do
            yield(element, height).tap { return it.value if it.is_a?(Stop) }

            break unless element.parent

            element = element.parent
            height += 1
          end
        end

        # Evaluates a block in the parent element context.
        # @example Add a sibling while forwarding its id
        #   root = SVG(id: "root")
        #   child = root.g(id: "child")
        #   child.With("sibling") { |id| line(id:) }
        # @param args [Array<Object>] positional arguments passed to the block
        # @param receiver [Sevgi::Graphics::Element] element whose parent becomes the block receiver
        # @param kwargs [Hash] keyword arguments passed to the block
        # @yield [*args, **kwargs] evaluates in the selected element's parent context
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when no block is given
        # @raise [Sevgi::ArgumentError] when receiver is not an element or has no parent
        def With(*args, receiver: self, **kwargs, &block)
          ArgumentError.("Block required") unless block
          ArgumentError.("Receiver must be an element") unless receiver.is_a?(Element)

          parent = receiver.parent
          ArgumentError.("Receiver has no parent") unless parent

          tap { parent.instance_exec(*args, **kwargs, &block) }
        end

        # Evaluates a block in this element context.
        # @example Select a receiver without consuming the block argument
        #   target = SVG(id: "target")
        #   source = SVG(id: "source")
        #   source.Within("child", receiver: target) { |id| g(id:) }
        # @param args [Array<Object>] positional arguments passed to the block
        # @param receiver [Object] block receiver
        # @param kwargs [Hash] keyword arguments passed to the block
        # @yield [*args, **kwargs] evaluates in the selected receiver context
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when no block is given
        def Within(*args, receiver: self, **kwargs, &block)
          ArgumentError.("Block required") unless block

          tap { receiver.instance_exec(*args, **kwargs, &block) }
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
          # Moves a validated batch to the front or back of a parent.
          # @param elements [Array<Sevgi::Graphics::Element>] elements to move
          # @param parent [Sevgi::Graphics::Element] target parent
          # @param front [Boolean] whether to prepend instead of append
          # @return [void]
          # @raise [Sevgi::ArgumentError] when an argument is incompatible, repeated, or would create a cycle
          def self.batch(elements, parent, front:)
            validate_batch(elements, parent)

            if front
              elements.reverse_each { it.AdoptFirst(parent) }
            else
              elements.each { it.Adopt(parent) }
            end
          end

          # Rejects target parents that would create a cycle.
          # @param element [Sevgi::Graphics::Element] element being moved
          # @param parent [Sevgi::Graphics::Element, Object] target parent
          # @return [void]
          # @raise [Sevgi::ArgumentError] when the parent is incompatible or would create a cycle
          def self.validate(element, parent)
            unless element.instance_of?(parent.class)
              ArgumentError.("Element type does not match the new parent type: #{element.class}")
            end

            ArgumentError.("Element cannot be adopted under itself") if parent.equal?(element)

            while parent.respond_to?(:Root?)
              ArgumentError.("Element cannot be adopted under its descendant") if parent.equal?(element)
              break if parent.Root?()

              parent = parent.parent
            end
          end

          # Normalizes an insertion index before tree mutation.
          # @param index [Integer] requested insertion index
          # @param size [Integer] number of available child positions
          # @return [Integer] normalized non-negative insertion index
          # @raise [Sevgi::ArgumentError] when the index is not an insertion position
          def self.index(index, size)
            ArgumentError.("Adoption index must be an Integer") unless index.is_a?(Integer)

            normalized = index.negative? ? size + index + 1 : index
            ArgumentError.("Adoption index is outside the child list") unless normalized.between?(0, size)

            normalized
          end

          # Returns an insertion index after accounting for a same-parent move.
          # @param element [Sevgi::Graphics::Element] element being moved
          # @param parent [Sevgi::Graphics::Element] target parent
          # @param index [Integer] requested insertion index
          # @return [Integer] normalized insertion index
          def self.index_for(element, parent, index)
            same_parent = element.parent.equal?(parent) && parent.children.include?(element)
            index(index, parent.children.size - (same_parent ? 1 : 0))
          end

          def self.validate_batch(elements, parent)
            seen = {}.compare_by_identity
            elements.each do |element|
              ArgumentError.("Element appears more than once in adoption batch") if seen.key?(element)

              seen[element] = true
              validate(element, parent)
            end
          end

          private_class_method :validate_batch
        end

        private_constant :Adoption
      end
    end
  end
end
