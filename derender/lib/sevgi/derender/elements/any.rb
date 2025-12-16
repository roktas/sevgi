# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      module Any
        def compile(*)
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
              *(Attributes.compile(attributes) if has_attributes)
            ].join(" ")
          end

          def tree
            [
              "#{leaf(has_content: false)} do",
              *children.map { |child| child.compile }.flatten,
              "end"
            ]
          end
      end
    end
  end
end
