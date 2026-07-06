# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      module Any
        def decompile(*)
          if children.any?
            children.one? && children.first.node.text? ? Array(leaf(has_attributes: attributes.any?)) : tree
          else
            Array(leaf(has_content: false))
          end
        end

        private

        def leaf(has_content: true, has_attributes: true)
          attributes = attributes!
          args = []
          args << Ruby.literal(content) if has_content
          args << Attributes.decompile(attributes) if has_attributes && attributes.any?

          args.empty? ? element : "#{element} #{args.join(", ")}"
        end

        def tree
          [
            "#{leaf(has_content: false)} do",
            *children.map(&:decompile).flatten,
            "end"
          ]
        end
      end
    end
  end
end
