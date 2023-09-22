# frozen_string_literal: true

require "sevgi/standard"

module Sevgi
  module Graphics
    module Mixtures
      module Validate
        module InstanceMethods
          def CData
            return if !contents || contents.empty?

            Graphics.Text(contents)
          end

          def Validate
            Traverse do |element|
              Standard.conform(
                element.name, attributes: element.attributes.list, cdata: element.CData, elements: element.children.map(&:name)
              )
            end
          end
        end
      end
    end
  end
end
