# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Duplicate
        def Duplicate(dx: nil, dy: nil, parent: nil, &block)
          duplicated = dup

          duplicated.Traverse do |element|
            element.children = element.children.map(&:dup)
            id = (element.attributes = element.attributes.dup).delete(:id)
            element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"] = id if id
            block&.call(element)
          end

          duplicated.Translate(dx, dy) if dx || dy

          duplicated.Adopt(parent)

          duplicated
        end

        def DuplicateH(dx, parent: nil, &block)
          Duplicate(dx:, dy: 0, parent:, &block)
        end

        def DuplicateV(dy, parent: nil, &block)
          Duplicate(dx: 0, dy:, parent:, &block)
        end
      end
    end
  end
end
