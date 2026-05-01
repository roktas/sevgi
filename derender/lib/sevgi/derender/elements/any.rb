# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      module Any
        def decompile(*)
          if children.any?
            children.count == 1 && children.first.node.text? ? Array(leaf(has_attributes: attributes.any?)) : tree
          else
            Array(leaf(has_content: false))
          end
        end

        private

          def leaf(has_content: true, has_attributes: true)
            attributes = attributes!
            [
              element,
              *("'#{content}', " if has_content),
              *(Attributes.decompile(attributes) if has_attributes)
            ].join(" ")
          end

          def tree
            [
              "#{leaf(has_content: false)} do",
              *children.map { |child| child.decompile }.flatten,
              "end"
            ]
          end
      end
    end
  end
end
