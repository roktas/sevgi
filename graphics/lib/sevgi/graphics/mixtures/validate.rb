# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Validate
        def CData
          return if !contents || contents.empty?

          Content.text(contents)
        end

        def NS?(name)
          self.class.attributes.key?(key = :"xmlns:#{name}") || TraverseUp { Stay(true) if it.has?(key) } || false
        end

        require "sevgi/standard"

        def Validate
          Traverse do |element|
            Standard.conform(
              element.name, attributes: element.attributes.list, cdata: element.CData, elements: element.children.map(&:name)
            )
          end
        end
      rescue ::LoadError
        def Validate(...) = true
      end
    end
  end
end
