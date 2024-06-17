# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Graphics
    module Mixtures
      module Core
        module InstanceMethods
          extend Forwardable
          def_delegators :@attributes, :[], :[]=, :has?
          def_delegators :@children, :first, :last, :at

          def Adopt(new_parent = nil, index: -1)
            tap do
              if new_parent
                ArgumentError.("Element type does not match the new parent type: #{self.class}") unless instance_of?(new_parent.class)
              else
                new_parent = parent
              end

              self.Orphan
              (@parent = new_parent).children.insert(index, self)
            end
          end

          def AdoptFirst(*)
            Adopt(*, index: 0)
          end

          def Append(*elements)
            tap { elements.each { it.Adopt(self) } }
          end

          def Element(tag, *contents, **attributes, &block)
            self.class.send(:new, tag.to_sym, contents: contents.map { Content.encoded(it) }, attributes:, parent: self, &block)
          end

          def Is?(name)
            self.name == name.to_sym
          end

          def Orphan
            parent.children&.delete(self) unless Root?
          end

          def Prepend(*elements)
            tap { elements.each { it.AdoptFirst(self) } }
          end

          def Root
            element = self
            while element.Root?
              element = element.parent
            end
            element
          end

          def Root?
            self.class.root?(self)
          end

          Traversal = Data.define(:value)

          def Stay(...) = Traversal.new(...)

          def Traverse(depth = 0, leave = nil, &block)
            ArgumentError.("Block required") unless block

            tap do
              yield(self, depth).tap { return it.value if it.is_a?(Traversal) }

              children.each { |child| child.Traverse(depth + 1, leave, &block) }

              leave&.call(self, depth).tap { return it.value if it.is_a?(Traversal) }
            end
          end

          def TraverseUp(height = 0, &block)
            ArgumentError.("Block required") unless block

            element = self

            loop do
              yield(element, height).tap { return it.value if it.is_a?(Traversal) }

              break if element.Root?

              element = element.parent
              height += 1
            end
          end

          def With(element = nil, ...)
            tap { (element || self).parent.instance_exec(self, ...) }
          end

          def Within(element = nil, ...)
            tap { (element || self).instance_exec(...) }
          end

          def <<(element)
            Append(element)
          end
        end
      end
    end
  end
end
