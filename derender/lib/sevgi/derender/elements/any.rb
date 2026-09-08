# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      # Default element strategy for ordinary SVG/XML elements.
      # @api private
      module Any
        # Converts this node into unformatted Sevgi DSL lines.
        # @return [Array<String>] unformatted Ruby source lines
        def decompile(*, namespaces: self.namespaces())
          if children.any?
            text_leaf? ? Array(leaf(Ruby.literal(content), namespaces:)) : tree(namespaces)
          else
            Array(leaf(namespaces:))
          end
        end

        private

        def leaf(*args, namespaces:)
          attributes = all_attributes(namespaces)
          args << Attributes.decompile(attributes) if attributes.any?

          return explicit_leaf(args) unless bare?

          args.empty? ? element : "#{element} #{args.join(", ")}"
        end

        def bare? = root? || (!Namespace.foreign?(node) && Ruby.bare_element?(element))

        def explicit_leaf(args)
          call = "Element(:#{Ruby.literal(element)}"

          args.empty? ? "#{call})" : "#{call}, #{args.join(", ")})"
        end

        def tree(namespaces)
          opening = inline_content? ? leaf(Ruby.literal(""), namespaces:) : leaf(namespaces:)

          [
            "#{opening} do",
            *children.map { it.send(:decompile) }.flatten,
            "end"
          ]
        end
      end
    end
  end
end
