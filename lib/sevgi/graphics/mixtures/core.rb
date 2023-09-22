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
            tap { elements.each { _1.Adopt(self) } }
          end

          def Orphan
            parent.children&.delete(self) unless Root?
          end

          def Prepend(*elements)
            tap { elements.each { _1.AdoptFirst(self) } }
          end

          def Root
            element = self
            while element
              break if element.Root?

              element = element.parent
            end
            element
          end

          def Root?
            self.class.root?(self)
          end

          def Traverse(depth = 0, leave = nil, &block)
            tap do
              yield(self, depth)

              children.each { |child| child.Traverse(depth + 1, leave, &block) }
              leave&.call(self, depth)
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
