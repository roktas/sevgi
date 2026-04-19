# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Identify
        class Identifiers
          attr_reader :element, :namespace, :collision

          def initialize(element)
            @element   = element
            @namespace = {}
            @collision = {}

            build
          end

          def conflict?
            !@collision.empty?
          end

          def [](*)
            @namespace[*]
          end

          private

            def build
              element.Traverse do |element|
                next unless (id = element[:id])

                if @namespace.key?(id)
                  (@collision[id] ||= [ @namespace[id] ]) << element
                else
                  @namespace[id] = element
                end
              end
            end
        end

        def Disidentify
          Traverse do |element|
            next unless element[:id]

            element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"] = element.attributes.delete(:id)
          end
        end

        def Identifiers = Identifiers.new(self)
      end
    end
  end
end
