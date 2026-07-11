# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      # Default element strategy for ordinary SVG/XML elements.
      # @api private
      module Any
        # Converts this node into unformatted Sevgi DSL lines.
        # @return [Array<String>] unformatted Ruby source lines
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

          return explicit_leaf(args) unless bare?

          args.empty? ? element : "#{element} #{args.join(", ")}"
        end

        def bare? = root? || (!Domain.foreign?(node) && Ruby.bare_element?(element))

        def explicit_leaf(args)
          call = "Element(:#{Ruby.literal(element)}"

          args.empty? ? "#{call})" : "#{call}, #{args.join(", ")})"
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
